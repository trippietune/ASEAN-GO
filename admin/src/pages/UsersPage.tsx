import { useCallback, useEffect, useState } from "react";
import { Input, message, Select, Space, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import { fetchUsers, updateUserRole } from "../api/admin";
import type { AdminUserRow, UserRole } from "../api/types";
import { useAuth } from "../auth/AuthContext";

const ROLE_COLORS: Record<UserRole, string> = { admin: "gold", moderator: "blue", user: "default" };

export default function UsersPage() {
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState<AdminUserRow[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState("");

  const load = useCallback(async (searchTerm?: string) => {
    setIsLoading(true);
    try {
      setUsers(await fetchUsers(searchTerm));
    } catch {
      message.error("โหลดรายชื่อผู้ใช้ไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleRoleChange = async (target: AdminUserRow, role: UserRole) => {
    try {
      const updated = await updateUserRole(target.id, role);
      setUsers((prev) => prev.map((u) => (u.id === target.id ? { ...u, ...updated } : u)));
      message.success("เปลี่ยน role แล้ว");
    } catch (err) {
      const msg =
        (err as { response?: { data?: { error?: string } } })?.response?.data?.error ?? "เปลี่ยน role ไม่สำเร็จ";
      message.error(msg);
    }
  };

  const columns: ColumnsType<AdminUserRow> = [
    { title: "ชื่อ", dataIndex: "display_name", key: "display_name" },
    { title: "อีเมล", dataIndex: "email", key: "email" },
    { title: "Level", dataIndex: "level", key: "level", width: 80 },
    { title: "XP", dataIndex: "xp", key: "xp", width: 80 },
    { title: "เหรียญ", dataIndex: "coin_balance", key: "coin_balance", width: 90 },
    {
      title: "สมัครเมื่อ",
      dataIndex: "created_at",
      key: "created_at",
      width: 130,
      render: (v: string) => dayjs(v).format("D MMM YYYY"),
    },
    {
      title: "Role",
      key: "role",
      width: 160,
      render: (_, target) => (
        <Select<UserRole>
          value={target.role}
          style={{ width: 140 }}
          onChange={(role) => handleRoleChange(target, role)}
          disabled={currentUser?.role !== "admin"}
          options={[
            { value: "user", label: <Tag color={ROLE_COLORS.user}>user</Tag> },
            { value: "moderator", label: <Tag color={ROLE_COLORS.moderator}>moderator</Tag> },
            { value: "admin", label: <Tag color={ROLE_COLORS.admin}>admin</Tag> },
          ]}
        />
      ),
    },
  ];

  return (
    <>
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder="ค้นหาชื่อหรืออีเมล"
          allowClear
          style={{ width: 280 }}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onSearch={(value) => load(value)}
        />
      </Space>
      <Table rowKey="id" columns={columns} dataSource={users} loading={isLoading} pagination={{ pageSize: 20 }} />
    </>
  );
}
