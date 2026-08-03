import { useCallback, useEffect, useState } from "react";
import { Button, Form, Input, InputNumber, message, Modal, Popconfirm, Select, Space, Switch, Table, Tag, Tooltip, Typography } from "antd";
import type { ColumnsType } from "antd/es/table";
import { createPin, deletePin, fetchPins, updatePin } from "../api/admin";
import type { CreatePinInput } from "../api/admin";
import type { AdminPin } from "../api/types";
import { useAuth } from "../auth/AuthContext";

const CATEGORY_OPTIONS = [
  { value: "food", label: "อาหาร" },
  { value: "shop", label: "ร้านค้า" },
  { value: "attraction", label: "สถานที่ท่องเที่ยว" },
  { value: "transport", label: "การเดินทาง" },
  { value: "lodging", label: "ที่พัก" },
  { value: "other", label: "อื่นๆ" },
];

export default function PinsPage() {
  const { user } = useAuth();
  // Creating/editing/deleting pin records directly is admin-only (prevents
  // duplicate/spam/false listings) — moderators can view this list but every
  // mutating control here is disabled for them, matching the backend's
  // requireAdmin gate on POST/PUT/DELETE /admin/pins.
  const isAdmin = user?.role === "admin";
  const [pins, setPins] = useState<AdminPin[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [scamEditTarget, setScamEditTarget] = useState<AdminPin | null>(null);
  const [scamMessage, setScamMessage] = useState("");
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [createForm] = Form.useForm<CreatePinInput>();

  const load = useCallback(async (searchTerm?: string) => {
    setIsLoading(true);
    try {
      setPins(await fetchPins(searchTerm));
    } catch {
      message.error("โหลดรายการ Pins ไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const toggleVerified = async (pin: AdminPin, isVerified: boolean) => {
    try {
      const updated = await updatePin(pin.id, { isVerified });
      setPins((prev) => prev.map((p) => (p.id === pin.id ? { ...p, ...updated } : p)));
      message.success(isVerified ? "ยืนยันจุดนี้แล้ว" : "ยกเลิกการยืนยันแล้ว");
    } catch {
      message.error("อัปเดตไม่สำเร็จ");
    }
  };

  const toggleScamAlert = async (pin: AdminPin, isScamAlert: boolean) => {
    if (isScamAlert) {
      setScamEditTarget(pin);
      setScamMessage(pin.scam_alert_message ?? "");
      return;
    }
    try {
      const updated = await updatePin(pin.id, { isScamAlert: false, scamAlertMessage: null });
      setPins((prev) => prev.map((p) => (p.id === pin.id ? { ...p, ...updated } : p)));
      message.success("ปิด Scam Alert แล้ว");
    } catch {
      message.error("อัปเดตไม่สำเร็จ");
    }
  };

  const submitScamAlert = async () => {
    if (!scamEditTarget) return;
    try {
      const updated = await updatePin(scamEditTarget.id, {
        isScamAlert: true,
        scamAlertMessage: scamMessage.trim() || null,
      });
      setPins((prev) => prev.map((p) => (p.id === scamEditTarget.id ? { ...p, ...updated } : p)));
      message.success("ตั้งค่า Scam Alert แล้ว");
      setScamEditTarget(null);
    } catch {
      message.error("อัปเดตไม่สำเร็จ");
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deletePin(id);
      setPins((prev) => prev.filter((p) => p.id !== id));
      message.success("ลบ Pin แล้ว");
    } catch {
      message.error("ลบไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  const openCreate = () => {
    createForm.resetFields();
    setCreateModalOpen(true);
  };

  const handleCreateSubmit = async () => {
    const values = await createForm.validateFields();
    try {
      const created = await createPin(values);
      setPins((prev) => [
        { ...created, review_count: 0, report_count: 0, submitted_by_name: null } as AdminPin,
        ...prev,
      ]);
      message.success("สร้าง Pin แล้ว");
      setCreateModalOpen(false);
    } catch (err) {
      if ((err as { errorFields?: unknown })?.errorFields) return;
      message.error("สร้างไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  const columns: ColumnsType<AdminPin> = [
    { title: "ชื่อ", dataIndex: "name", key: "name", fixed: "left", width: 200 },
    { title: "หมวดหมู่", dataIndex: "category", key: "category", width: 110 },
    {
      title: "พื้นที่",
      key: "location",
      width: 160,
      render: (_, pin) => `${pin.city ?? "-"}, ${pin.country}`,
    },
    { title: "Safety Score", dataIndex: "safety_score", key: "safety_score", width: 110, sorter: (a, b) => a.safety_score - b.safety_score },
    { title: "รีวิว", dataIndex: "review_count", key: "review_count", width: 80 },
    {
      title: "รายงานเสี่ยง",
      dataIndex: "report_count",
      key: "report_count",
      width: 110,
      render: (count: number) => (count > 0 ? <Tag color="volcano">{count}</Tag> : count),
    },
    {
      title: "ยืนยันแล้ว",
      key: "is_verified",
      width: 100,
      render: (_, pin) => (
        <Switch checked={pin.is_verified} disabled={!isAdmin} onChange={(checked) => toggleVerified(pin, checked)} />
      ),
    },
    {
      title: "Scam Alert",
      key: "is_scam_alert",
      width: 220,
      render: (_, pin) => (
        <Space direction="vertical" size={0}>
          <Switch checked={pin.is_scam_alert} disabled={!isAdmin} onChange={(checked) => toggleScamAlert(pin, checked)} />
          {pin.is_scam_alert && pin.scam_alert_message && (
            <Typography.Text type="secondary" style={{ fontSize: 12 }}>
              {pin.scam_alert_message}
            </Typography.Text>
          )}
        </Space>
      ),
    },
    { title: "ผู้ส่ง", dataIndex: "submitted_by_name", key: "submitted_by_name", width: 140, render: (v) => v ?? "-" },
    {
      title: "",
      key: "actions",
      fixed: "right",
      width: 90,
      render: (_, pin) =>
        isAdmin ? (
          <Popconfirm title="ลบ Pin นี้ถาวร?" onConfirm={() => handleDelete(pin.id)} okText="ลบ" cancelText="ยกเลิก">
            <Button danger size="small">
              ลบ
            </Button>
          </Popconfirm>
        ) : (
          <Tooltip title="เฉพาะ Admin เท่านั้น">
            <Button danger size="small" disabled>
              ลบ
            </Button>
          </Tooltip>
        ),
    },
  ];

  return (
    <>
      <Space style={{ marginBottom: 16 }}>
        {isAdmin ? (
          <Button type="primary" onClick={openCreate}>
            + เพิ่ม Pin
          </Button>
        ) : (
          <Tooltip title="เฉพาะ Admin เท่านั้นที่สร้าง Pin ได้">
            <Button type="primary" disabled>
              + เพิ่ม Pin
            </Button>
          </Tooltip>
        )}
        <Input.Search
          placeholder="ค้นหาชื่อ หรือเมือง"
          allowClear
          style={{ width: 280 }}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onSearch={(value) => load(value)}
        />
      </Space>
      <Table
        rowKey="id"
        columns={columns}
        dataSource={pins}
        loading={isLoading}
        scroll={{ x: 1300 }}
        pagination={{ pageSize: 20 }}
      />
      <Modal
        title={`ตั้งค่า Scam Alert: ${scamEditTarget?.name ?? ""}`}
        open={scamEditTarget !== null}
        onOk={submitScamAlert}
        onCancel={() => setScamEditTarget(null)}
        okText="บันทึก"
        cancelText="ยกเลิก"
      >
        <Input.TextArea
          rows={3}
          placeholder="ข้อความเตือน (แสดงให้ผู้ใช้เห็น)"
          value={scamMessage}
          onChange={(e) => setScamMessage(e.target.value)}
        />
      </Modal>
      <Modal
        title="เพิ่ม Pin ใหม่"
        open={createModalOpen}
        onOk={handleCreateSubmit}
        onCancel={() => setCreateModalOpen(false)}
        okText="สร้าง"
        cancelText="ยกเลิก"
        destroyOnHidden
      >
        <Form form={createForm} layout="vertical">
          <Form.Item name="name" label="ชื่อ" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="category" label="หมวดหมู่" rules={[{ required: true }]}>
            <Select options={CATEGORY_OPTIONS} />
          </Form.Item>
          <Form.Item name="description" label="รายละเอียด">
            <Input.TextArea rows={2} />
          </Form.Item>
          <Form.Item name="country" label="ประเทศ" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="city" label="เมือง">
            <Input />
          </Form.Item>
          <Space>
            <Form.Item name="lat" label="ละติจูด" rules={[{ required: true }]}>
              <InputNumber min={-90} max={90} step={0.0001} />
            </Form.Item>
            <Form.Item name="lng" label="ลองจิจูด" rules={[{ required: true }]}>
              <InputNumber min={-180} max={180} step={0.0001} />
            </Form.Item>
          </Space>
        </Form>
      </Modal>
    </>
  );
}
