import { useCallback, useEffect, useState } from "react";
import { Button, Input, message, Modal, Popconfirm, Segmented, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import { approvePinSuggestion, fetchPinSuggestions, rejectPinSuggestion } from "../api/admin";
import type { AdminPinSuggestion, PinSuggestionStatus } from "../api/types";

const STATUS_COLORS: Record<PinSuggestionStatus, string> = { pending: "gold", approved: "green", rejected: "red" };

export default function PinSuggestionsPage() {
  const [suggestions, setSuggestions] = useState<AdminPinSuggestion[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<PinSuggestionStatus | "all">("pending");
  const [rejectTarget, setRejectTarget] = useState<AdminPinSuggestion | null>(null);
  const [rejectReason, setRejectReason] = useState("");

  const load = useCallback(async (status: PinSuggestionStatus | "all") => {
    setIsLoading(true);
    try {
      setSuggestions(await fetchPinSuggestions(status === "all" ? undefined : status));
    } catch {
      message.error("โหลดรายการ Pin Suggestions ไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load(statusFilter);
  }, [load, statusFilter]);

  const handleApprove = async (id: string) => {
    try {
      await approvePinSuggestion(id);
      message.success("อนุมัติแล้ว สร้าง Pin ใหม่เรียบร้อย");
      load(statusFilter);
    } catch {
      message.error("อนุมัติไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  const submitReject = async () => {
    if (!rejectTarget) return;
    try {
      await rejectPinSuggestion(rejectTarget.id, rejectReason.trim() || undefined);
      message.success("ปฏิเสธคำแนะนำแล้ว");
      setRejectTarget(null);
      load(statusFilter);
    } catch {
      message.error("ดำเนินการไม่สำเร็จ");
    }
  };

  const columns: ColumnsType<AdminPinSuggestion> = [
    { title: "ชื่อ", dataIndex: "name", key: "name" },
    { title: "หมวดหมู่", dataIndex: "category", key: "category", width: 110 },
    {
      title: "พื้นที่",
      key: "location",
      width: 160,
      render: (_, s) => `${s.city ?? "-"}, ${s.country}`,
    },
    { title: "ผู้แนะนำ", dataIndex: "submitted_by_name", key: "submitted_by_name", render: (v) => v ?? "-" },
    {
      title: "สถานะ",
      dataIndex: "status",
      key: "status",
      width: 110,
      render: (status: PinSuggestionStatus) => <Tag color={STATUS_COLORS[status]}>{status}</Tag>,
    },
    {
      title: "วันที่ส่ง",
      dataIndex: "created_at",
      key: "created_at",
      width: 130,
      render: (v: string) => dayjs(v).format("D MMM YYYY"),
    },
    {
      title: "",
      key: "actions",
      width: 200,
      render: (_, s) =>
        s.status === "pending" ? (
          <div style={{ display: "flex", gap: 8 }}>
            <Popconfirm title="อนุมัติคำแนะนำนี้และสร้าง Pin?" onConfirm={() => handleApprove(s.id)} okText="อนุมัติ" cancelText="ยกเลิก">
              <Button size="small" type="primary">
                อนุมัติ
              </Button>
            </Popconfirm>
            <Button
              size="small"
              danger
              onClick={() => {
                setRejectTarget(s);
                setRejectReason("");
              }}
            >
              ปฏิเสธ
            </Button>
          </div>
        ) : null,
    },
  ];

  return (
    <>
      <Segmented
        style={{ marginBottom: 16 }}
        value={statusFilter}
        onChange={(v) => setStatusFilter(v as typeof statusFilter)}
        options={[
          { label: "รอตรวจสอบ", value: "pending" },
          { label: "อนุมัติแล้ว", value: "approved" },
          { label: "ปฏิเสธแล้ว", value: "rejected" },
          { label: "ทั้งหมด", value: "all" },
        ]}
      />
      <Table rowKey="id" columns={columns} dataSource={suggestions} loading={isLoading} pagination={{ pageSize: 20 }} />
      <Modal
        title={`ปฏิเสธคำแนะนำ: ${rejectTarget?.name ?? ""}`}
        open={rejectTarget !== null}
        onOk={submitReject}
        onCancel={() => setRejectTarget(null)}
        okText="ปฏิเสธ"
        cancelText="ยกเลิก"
        okButtonProps={{ danger: true }}
      >
        <Input.TextArea
          rows={3}
          placeholder="เหตุผล (ถ้ามี)"
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
        />
      </Modal>
    </>
  );
}
