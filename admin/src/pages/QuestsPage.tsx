import { useCallback, useEffect, useState } from "react";
import { Button, Form, Input, InputNumber, message, Modal, Popconfirm, Select, Space, Table } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import { createQuest, deleteQuest, fetchQuests, updateQuest } from "../api/admin";
import type { CreateQuestInput } from "../api/admin";
import type { AdminQuest as AdminQuestType } from "../api/types";

export default function QuestsPage() {
  const [quests, setQuests] = useState<AdminQuestType[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<AdminQuestType | null>(null);
  const [form] = Form.useForm<CreateQuestInput>();

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      setQuests(await fetchQuests());
    } catch {
      message.error("โหลดรายการ Quests ไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ questType: "daily", xpReward: 10, coinReward: 0 });
    setModalOpen(true);
  };

  const openEdit = (quest: AdminQuestType) => {
    setEditing(quest);
    form.setFieldsValue({
      title: quest.title,
      description: quest.description ?? undefined,
      questType: quest.quest_type,
      xpReward: quest.xp_reward,
      coinReward: quest.coin_reward,
      country: quest.country ?? undefined,
    });
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        const updated = await updateQuest(editing.id, values);
        setQuests((prev) => prev.map((q) => (q.id === editing.id ? { ...q, ...updated } : q)));
        message.success("แก้ไข Quest แล้ว");
      } else {
        const created = await createQuest(values);
        setQuests((prev) => [{ ...created, completed_count: 0, pin_name: null }, ...prev]);
        message.success("สร้าง Quest แล้ว");
      }
      setModalOpen(false);
    } catch (err) {
      if ((err as { errorFields?: unknown })?.errorFields) return;
      message.error("บันทึกไม่สำเร็จ");
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteQuest(id);
      setQuests((prev) => prev.filter((q) => q.id !== id));
      message.success("ลบ Quest แล้ว");
    } catch {
      message.error("ลบไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  const columns: ColumnsType<AdminQuestType> = [
    { title: "ชื่อ Quest", dataIndex: "title", key: "title" },
    { title: "ประเภท", dataIndex: "quest_type", key: "quest_type", width: 110 },
    { title: "XP", dataIndex: "xp_reward", key: "xp_reward", width: 80 },
    { title: "เหรียญ", dataIndex: "coin_reward", key: "coin_reward", width: 90 },
    { title: "Pin ที่ผูก", dataIndex: "pin_name", key: "pin_name", render: (v) => v ?? "-" },
    { title: "ประเทศ", dataIndex: "country", key: "country", width: 100, render: (v) => v ?? "-" },
    { title: "สำเร็จแล้ว", dataIndex: "completed_count", key: "completed_count", width: 100 },
    {
      title: "สิ้นสุด",
      dataIndex: "active_until",
      key: "active_until",
      width: 130,
      render: (v: string | null) => (v ? dayjs(v).format("D MMM YYYY") : "ไม่มีกำหนด"),
    },
    {
      title: "",
      key: "actions",
      width: 150,
      render: (_, quest) => (
        <Space>
          <Button size="small" onClick={() => openEdit(quest)}>
            แก้ไข
          </Button>
          <Popconfirm title="ลบ Quest นี้ถาวร?" onConfirm={() => handleDelete(quest.id)} okText="ลบ" cancelText="ยกเลิก">
            <Button danger size="small">
              ลบ
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <>
      <Space style={{ marginBottom: 16 }}>
        <Button type="primary" onClick={openCreate}>
          + สร้าง Quest
        </Button>
      </Space>
      <Table rowKey="id" columns={columns} dataSource={quests} loading={isLoading} pagination={{ pageSize: 20 }} />
      <Modal
        title={editing ? "แก้ไข Quest" : "สร้าง Quest ใหม่"}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText="บันทึก"
        cancelText="ยกเลิก"
        destroyOnHidden
      >
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="ชื่อ Quest" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="description" label="รายละเอียด">
            <Input.TextArea rows={2} />
          </Form.Item>
          <Form.Item name="questType" label="ประเภท" rules={[{ required: true }]}>
            <Select
              options={[
                { value: "daily", label: "รายวัน" },
                { value: "weekly", label: "รายสัปดาห์" },
                { value: "recommended", label: "แนะนำ" },
              ]}
            />
          </Form.Item>
          <Space>
            <Form.Item name="xpReward" label="XP Reward" rules={[{ required: true }]}>
              <InputNumber min={0} />
            </Form.Item>
            <Form.Item name="coinReward" label="Coin Reward" rules={[{ required: true }]}>
              <InputNumber min={0} />
            </Form.Item>
          </Space>
          <Form.Item name="country" label="ประเทศ (ถ้ามี)">
            <Input />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
}
