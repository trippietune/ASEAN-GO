import type { Server as HttpServer } from "http";
import { Server as SocketIOServer, Socket } from "socket.io";
import jwt from "jsonwebtoken";
import { env } from "../config/env";

interface AuthedSocket extends Socket {
  userId?: string;
}

let io: SocketIOServer | undefined;

/// Rooms are named `user:<id>` so any server module can push an event to a
/// specific signed-in user without tracking socket ids itself.
function userRoom(userId: string): string {
  return `user:${userId}`;
}

export function initSocketServer(httpServer: HttpServer): SocketIOServer {
  io = new SocketIOServer(httpServer, {
    cors: { origin: "*" },
  });

  io.use((socket: AuthedSocket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      return next(new Error("Missing auth token"));
    }
    try {
      const payload = jwt.verify(token, env.jwtSecret) as { sub: string };
      socket.userId = payload.sub;
      next();
    } catch {
      next(new Error("Invalid or expired token"));
    }
  });

  io.on("connection", (socket: AuthedSocket) => {
    if (socket.userId) {
      socket.join(userRoom(socket.userId));
    }
  });

  return io;
}

/// Push a real-time event to every connection this user currently has open.
/// No-op (safe to call) if the socket server hasn't been initialized or the
/// user isn't currently connected — callers don't need to check either case.
export function emitToUser(userId: string, event: string, payload: unknown): void {
  io?.to(userRoom(userId)).emit(event, payload);
}
