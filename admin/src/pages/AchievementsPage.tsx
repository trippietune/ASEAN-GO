import { useCallback, useEffect, useState } from "react";
import { Button, Form, Input, InputNumber, message, Modal, Popconfirm, Select, Space, Switch, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import {
  createAchievement,
  deleteAchievement,
  fetchAchievements,
  fetchQuestChapters,
  fetchUsers,
  grantAchievement,
  updateAchievement,
} from "../api/admin";
import type { CreateAchievementInput } from "../api/admin";
import type { AchievementCriteriaType, AdminAchievement, AdminQuestChapter, AdminUserRow } from "../api/types";

const CRITERIA_LABELS: Record<AchievementCriteriaType, string> = {
  quests_completed: "จำนวนเควสที่ทำสำเร็จ",
  checkins: "จำนวนการเช็คอิน",
  level_reached: "เลเวลที่ถึง",
  category_visits: "เยี่ยมชมหมวดหมู่ครบจำนวน",
  chapter_completed: "จบ Chapter",
  manual: "มอบโดยแอดมินเท่านั้น",
};

export default function AchievementsPage() {
  const [achievements, setAchievements] = useState<AdminAchievement[]>([]);
  const [chapters, setChapters] = useState<AdminQuestChapter[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<AdminAchievement | null>(null);
  const [form] = Form.useForm<CreateAchievementInput>();

  const [grantOpen, setGrantOpen] = useState(false);
  const [grantTarget, setGrantTarget] = useState<AdminAchievement | null>(null);
  const [userOptions, setUserOptions] = useState<AdminUserRow[]>([]);
  const [grantForm] = Form.useForm<{ userId: string }>();

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      setAchievements(await fetchAchievements());
    } catch {
      message.error("โหลดรายการ Achievements ไม่สำเร็จ");
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
    form.setFieldsValue({ criteriaType: "quests_completed", xpReward: 0, coinReward: 0, isActive: true });
    setModalOpen(true);
    setChapters(await fetchQuestChapters());
  };

  const openEdit = async (achievement: AdminAchievement) => {
    setEditing(achievement);
    form.setFieldsValue({
      title: achievement.title,
      description: achievement.description ?? undefined,
      iconUrl: achievement.icon_url ?? undefined,
      criteriaType: achievement.criteria_type,
      criteriaCategory: achievement.criteria_category ?? undefined,
      criteriaChapterId: achievement.criteria_chapter_id ?? undefined,
      countThreshold: achievement.count_threshold ?? undefined,
      xpReward: achievement.xp_reward,
      coinReward: achievement.coin_reward,
      isActive: achievement.is_active,
    });
    setModalOpen(true);
    setChapters(await fetchQuestChapters());
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        const updated = await updateAchievement(editing.id, values);
        setAchievements((prev) => prev.map((a) => (a.id === editing.id ? { ...a, ...updated } : a)));
        message.success("แก้ไข Achievement แล้ว");
      } else {
        const created = await createAchievement(values);
        setAchievements((prev) => [created, ...prev]);
        message.success("สร้าง Achievement แล้ว");
      }
      setModalOpen(false);
    } catch (err) {
      if ((err as { errorFields?: unknown })?.errorFields) return;
      message.error("บันทึกไม่สำเร็จ");
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteAchievement(id);
      setAchievements((prev) => prev.filter((a) => a.id !== id));
      message.success("ลบ Achievement แล้ว");
    } catch {
      message.error("ลบไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  const openGrant = (achievement: AdminAchievement) => {
    setGrantTarget(achievement);
    grantForm.resetFields();
    setUserOptions([]);
    setGrantOpen(true);
  };

  const handleUserSearch = async (search: string) => {
    if (!search) return;
    setUserOptions(await fetchUsers(search));
  };

  const handleGrant = async () => {
    if (!grantTarget) return;
    const values = await grantForm.validateFields();
    try {
      await grantAchievement(grantTarget.id, values.userId);
      message.success("มอบ Achievement แล้ว");
      setGrantOpen(false);
    } catch (err) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      if (status === 409) {
        message.error("ผู้ใช้นี้มี Achievement นี้อยู่แล้ว");
      } else {
        message.error("มอบไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
      }
    }
  };

  const columns: ColumnsType<AdminAchievement> = [
    { title: "ชื่อ", dataIndex: "title", key: "title" },
    {
      title: "เงื่อนไข",
      dataIndex: "criteria_type",
      key: "criteria_type",
      width: 180,
      render: (v: AchievementCriteriaType) => CRITERIA_LABELS[v] ?? v,
    },
    { title: "จำนวนที่ต้องการ", dataIndex: "count_threshold", key: "count_threshold", width: 110, render: (v) => v ?? "-" },
    { title: "XP", dataIndex: "xp_reward", key: "xp_reward", width: 80 },
    { title: "เหรียญ", dataIndex: "coin_reward", key: "coin_reward", width: 90 },
    {
      title: "สถานะ",
      dataIndex: "is_active",
      key: "is_active",
      width: 100,
      render: (v: boolean) => (v ? <Tag color="green">ใช้งาน</Tag> : <Tag>ปิดใช้งาน</Tag>),
    },
    {
      title: "",
      key: "actions",
      width: 220,
      render: (_, achievement) => (
        <Space>
          <Button size="small" onClick={() => openEdit(achievement)}>
            แก้ไข
          </Button>
          <Button size="small" onClick={() => openGrant(achievement)}>
            มอบให้ผู้ใช้
          </Button>
          <Popconfirm title="ลบ Achievement นี้ถาวร?" onConfirm={() => handleDelete(achievement.id)} okText="ลบ" cancelText="ยกเลิก">
            <Button danger size="small">
              ลบ
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  const criteriaType = Form.useWatch("criteriaType", form);

  return (
    <>
      <Space style={{ marginBottom: 16 }}>
        <Button type="primary" onClick={openCreate}>
          + สร้าง Achievement
        </Button>
      </Space>
      <Table rowKey="id" columns={columns} dataSource={achievements} loading={isLoading} pagination={{ pageSize: 20 }} />

      <Modal
        title={editing ? "แก้ไข Achievement" : "สร้าง Achievement ใหม่"}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText="บันทึก"
        cancelText="ยกเลิก"
        destroyOnHidden
      >
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="ชื่อ Achievement" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="description" label="รายละเอียด">
            <Input.TextArea rows={2} />
          </Form.Item>
          <Form.Item name="iconUrl" label="Icon URL">
            <Input placeholder="https://..." />
          </Form.Item>
          <Form.Item name="criteriaType" label="เงื่อนไข" rules={[{ required: true }]}>
            <Select options={Object.entries(CRITERIA_LABELS).map(([value, label]) => ({ value, label }))} />
          </Form.Item>
          {criteriaType === "category_visits" && (
            <Form.Item name="criteriaCategory" label="หมวดหมู่" rules={[{ required: true }]}>
              <Input placeholder="เช่น food, attraction" />
            </Form.Item>
          )}
          {criteriaType === "chapter_completed" && (
            <Form.Item name="criteriaChapterId" label="Chapter" rules={[{ required: true }]}>
              <Select options={chapters.map((c) => ({ value: c.id, label: `${c.order_index}. ${c.title}` }))} />
            </Form.Item>
          )}
          {["quests_completed", "checkins", "level_reached", "category_visits"].includes(criteriaType) && (
            <Form.Item name="countThreshold" label="จำนวนที่ต้องการ" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: "100%" }} />
            </Form.Item>
          )}
          <Space>
            <Form.Item name="xpReward" label="XP Reward" rules={[{ required: true }]}>
              <InputNumber min={0} />
            </Form.Item>
            <Form.Item name="coinReward" label="Coin Reward" rules={[{ required: true }]}>
              <InputNumber min={0} />
            </Form.Item>
          </Space>
          <Form.Item name="isActive" label="เปิดใช้งาน" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title={`มอบ "${grantTarget?.title ?? ""}" ให้ผู้ใช้`}
        open={grantOpen}
        onOk={handleGrant}
        onCancel={() => setGrantOpen(false)}
        okText="มอบ"
        cancelText="ยกเลิก"
        destroyOnHidden
      >
        <Form form={grantForm} layout="vertical">
          <Form.Item name="userId" label="ผู้ใช้" rules={[{ required: true }]}>
            <Select
              showSearch
              placeholder="ค้นหาด้วยชื่อหรืออีเมล"
              filterOption={false}
              onSearch={handleUserSearch}
              options={userOptions.map((u) => ({ value: u.id, label: `${u.display_name} (${u.email})` }))}
            />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
}
