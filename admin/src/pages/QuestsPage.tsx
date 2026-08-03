import { useCallback, useEffect, useState } from "react";
import { Button, Divider, Form, Input, InputNumber, List, message, Modal, Popconfirm, Select, Space, Table } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import {
  createQuest,
  createUnlockRequirement,
  deleteQuest,
  deleteUnlockRequirement,
  fetchPins,
  fetchQuestChapters,
  fetchQuests,
  fetchUnlockRequirements,
  updateQuest,
} from "../api/admin";
import type { CreateQuestInput, CreateUnlockRequirementInput } from "../api/admin";
import type {
  AdminPin,
  AdminQuest as AdminQuestType,
  AdminQuestChapter,
  AdminQuestUnlockRequirement,
  QuestType,
  UnlockRequirementType,
} from "../api/types";

const QUEST_TYPE_LABELS: Record<QuestType, string> = {
  daily: "รายวัน",
  location: "สถานที่",
  category: "หมวดหมู่",
  level: "เลเวล",
  story: "เนื้อเรื่อง",
};

const REQUIREMENT_TYPE_LABELS: Record<UnlockRequirementType, string> = {
  level: "เลเวลขั้นต่ำ",
  quest: "ต้องทำเควสอื่นก่อน",
  checkin: "ต้องเช็คอิน ณ Pin",
  category: "เยี่ยมชมหมวดหมู่ครบจำนวน",
  location: "เยี่ยมชมสถานที่ครบจำนวน",
};

function describeRequirement(r: AdminQuestUnlockRequirement): string {
  switch (r.requirement_type) {
    case "level":
      return `เลเวล ${r.min_level}+`;
    case "quest":
      return `ทำเควส ${r.required_quest_id} ก่อน`;
    case "checkin":
      return `เช็คอิน ณ Pin ${r.required_pin_id}`;
    case "category":
      return `เยี่ยมชม ${r.count_threshold} pins หมวด ${r.category}`;
    case "location":
      return r.city
        ? `เยี่ยมชม ${r.count_threshold} pins ใน ${r.city}, ${r.country}`
        : `เยี่ยมชม ${r.count_threshold} pins ใน ${r.country}`;
    default:
      return r.requirement_type;
  }
}

// Sub-panel for managing a quest's unlock requirements — only usable once
// the quest exists (needs a real questId), so it only renders when editing.
function UnlockRequirementsPanel({ questId }: { questId: string }) {
  const [requirements, setRequirements] = useState<AdminQuestUnlockRequirement[]>([]);
  const [loading, setLoading] = useState(true);
  const [reqForm] = Form.useForm<CreateUnlockRequirementInput>();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setRequirements(await fetchUnlockRequirements(questId));
    } catch {
      message.error("โหลดเงื่อนไขปลดล็อคไม่สำเร็จ");
    } finally {
      setLoading(false);
    }
  }, [questId]);

  useEffect(() => {
    load();
  }, [load]);

  const requirementType = Form.useWatch("requirementType", reqForm);

  const handleAdd = async () => {
    const values = await reqForm.validateFields();
    try {
      const created = await createUnlockRequirement(questId, values);
      setRequirements((prev) => [...prev, created]);
      reqForm.resetFields();
      message.success("เพิ่มเงื่อนไขแล้ว");
    } catch {
      message.error("เพิ่มเงื่อนไขไม่สำเร็จ");
    }
  };

  const handleRemove = async (id: string) => {
    try {
      await deleteUnlockRequirement(questId, id);
      setRequirements((prev) => prev.filter((r) => r.id !== id));
      message.success("ลบเงื่อนไขแล้ว");
    } catch {
      message.error("ลบไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  return (
    <>
      <Divider plain>เงื่อนไขการปลดล็อค</Divider>
      <List
        size="small"
        loading={loading}
        dataSource={requirements}
        locale={{ emptyText: "ไม่มีเงื่อนไข — ปลดล็อคทันที" }}
        renderItem={(r) => (
          <List.Item
            actions={[
              r.source === "admin" ? (
                <Popconfirm key="del" title="ลบเงื่อนไขนี้?" onConfirm={() => handleRemove(r.id)} okText="ลบ" cancelText="ยกเลิก">
                  <Button size="small" danger>
                    ลบ
                  </Button>
                </Popconfirm>
              ) : (
                <span key="auto" style={{ color: "#999", fontSize: 12 }}>
                  auto (chapter)
                </span>
              ),
            ]}
          >
            {REQUIREMENT_TYPE_LABELS[r.requirement_type]}: {describeRequirement(r)}
          </List.Item>
        )}
      />
      <Space style={{ marginTop: 12 }} wrap>
        <Form form={reqForm} layout="inline">
          <Form.Item name="requirementType" rules={[{ required: true }]}>
            <Select
              style={{ width: 180 }}
              placeholder="ประเภทเงื่อนไข"
              options={Object.entries(REQUIREMENT_TYPE_LABELS).map(([value, label]) => ({ value, label }))}
            />
          </Form.Item>
          {requirementType === "level" && (
            <Form.Item name="minLevel" rules={[{ required: true }]}>
              <InputNumber min={1} placeholder="เลเวล" />
            </Form.Item>
          )}
          {requirementType === "quest" && (
            <Form.Item name="requiredQuestId" rules={[{ required: true }]}>
              <Input placeholder="Quest ID ที่ต้องทำก่อน" style={{ width: 220 }} />
            </Form.Item>
          )}
          {requirementType === "checkin" && (
            <Form.Item name="requiredPinId" rules={[{ required: true }]}>
              <Input placeholder="Pin ID ที่ต้องเช็คอิน" style={{ width: 220 }} />
            </Form.Item>
          )}
          {requirementType === "category" && (
            <>
              <Form.Item name="category" rules={[{ required: true }]}>
                <Input placeholder="หมวดหมู่" style={{ width: 140 }} />
              </Form.Item>
              <Form.Item name="countThreshold" rules={[{ required: true }]}>
                <InputNumber min={1} placeholder="จำนวน" />
              </Form.Item>
            </>
          )}
          {requirementType === "location" && (
            <>
              <Form.Item name="country" rules={[{ required: true }]}>
                <Input placeholder="ประเทศ" style={{ width: 140 }} />
              </Form.Item>
              <Form.Item name="city">
                <Input placeholder="เมือง (ถ้ามี)" style={{ width: 140 }} />
              </Form.Item>
              <Form.Item name="countThreshold" rules={[{ required: true }]}>
                <InputNumber min={1} placeholder="จำนวน" />
              </Form.Item>
            </>
          )}
        </Form>
        <Button size="small" onClick={handleAdd}>
          + เพิ่มเงื่อนไข
        </Button>
      </Space>
    </>
  );
}

export default function QuestsPage() {
  const [quests, setQuests] = useState<AdminQuestType[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<AdminQuestType | null>(null);
  const [pins, setPins] = useState<AdminPin[]>([]);
  const [chapters, setChapters] = useState<AdminQuestChapter[]>([]);
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

  const openCreate = async () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ questType: "daily", xpReward: 10, coinReward: 0 });
    setModalOpen(true);
    setPins(await fetchPins());
    setChapters(await fetchQuestChapters());
  };

  const openEdit = async (quest: AdminQuestType) => {
    setEditing(quest);
    form.setFieldsValue({
      title: quest.title,
      description: quest.description ?? undefined,
      questType: quest.quest_type,
      category: quest.category ?? undefined,
      chapterId: quest.chapter_id ?? undefined,
      chapterOrder: quest.chapter_order ?? undefined,
      xpReward: quest.xp_reward,
      coinReward: quest.coin_reward,
      pinId: quest.pin_id ?? undefined,
      country: quest.country ?? undefined,
    });
    setModalOpen(true);
    setPins(await fetchPins());
    setChapters(await fetchQuestChapters());
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
    { title: "ประเภท", dataIndex: "quest_type", key: "quest_type", width: 110, render: (v: QuestType) => QUEST_TYPE_LABELS[v] ?? v },
    { title: "หมวดหมู่", dataIndex: "category", key: "category", width: 110, render: (v) => v ?? "-" },
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
        width={640}
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
              options={Object.entries(QUEST_TYPE_LABELS).map(([value, label]) => ({ value, label }))}
            />
          </Form.Item>
          <Form.Item name="category" label="หมวดหมู่ (สำหรับเควสประเภทหมวดหมู่)">
            <Input placeholder="เช่น food, attraction" />
          </Form.Item>
          <Space>
            <Form.Item name="chapterId" label="Chapter (สำหรับเควสเนื้อเรื่อง)">
              <Select
                allowClear
                style={{ width: 220 }}
                placeholder="ไม่ผูก Chapter"
                options={chapters.map((c) => ({ value: c.id, label: `${c.order_index}. ${c.title}` }))}
              />
            </Form.Item>
            <Form.Item
              name="chapterOrder"
              label="ลำดับใน Chapter"
              help="เควสจะปลดล็อคตามลำดับนี้ในแต่ละ Chapter"
            >
              <InputNumber min={1} max={1000} />
            </Form.Item>
          </Space>
          <Space>
            <Form.Item name="xpReward" label="XP Reward" rules={[{ required: true }]}>
              <InputNumber min={0} />
            </Form.Item>
            <Form.Item name="coinReward" label="Coin Reward" rules={[{ required: true }]}>
              <InputNumber min={0} />
            </Form.Item>
          </Space>
          <Form.Item
            name="pinId"
            label="Pin ที่ผูก"
            help="การตั้งค่า Pin จะสร้างเงื่อนไขปลดล็อคแบบเช็คอินให้อัตโนมัติ"
          >
            <Select
              allowClear
              showSearch
              placeholder="ไม่ผูก Pin"
              options={pins.map((p) => ({ value: p.id, label: `${p.name} (${p.country})` }))}
              filterOption={(input, option) => (option?.label ?? "").toLowerCase().includes(input.toLowerCase())}
            />
          </Form.Item>
          <Form.Item name="country" label="ประเทศ (ถ้ามี)">
            <Input />
          </Form.Item>
        </Form>
        {editing && <UnlockRequirementsPanel questId={editing.id} />}
      </Modal>
    </>
  );
}
