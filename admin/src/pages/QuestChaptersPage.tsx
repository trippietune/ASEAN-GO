import { useCallback, useEffect, useState } from "react";
import { Button, Form, Input, InputNumber, message, Modal, Popconfirm, Space, Table } from "antd";
import type { ColumnsType } from "antd/es/table";
import { createQuestChapter, deleteQuestChapter, fetchQuestChapters, updateQuestChapter } from "../api/admin";
import type { CreateQuestChapterInput } from "../api/admin";
import type { AdminQuestChapter } from "../api/types";

export default function QuestChaptersPage() {
  const [chapters, setChapters] = useState<AdminQuestChapter[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<AdminQuestChapter | null>(null);
  const [form] = Form.useForm<CreateQuestChapterInput>();

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      setChapters(await fetchQuestChapters());
    } catch {
      message.error("โหลดรายการ Chapters ไม่สำเร็จ");
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
    form.setFieldsValue({ orderIndex: (chapters.at(-1)?.order_index ?? 0) + 1 });
    setModalOpen(true);
  };

  const openEdit = (chapter: AdminQuestChapter) => {
    setEditing(chapter);
    form.setFieldsValue({
      title: chapter.title,
      description: chapter.description ?? undefined,
      orderIndex: chapter.order_index,
    });
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        const updated = await updateQuestChapter(editing.id, values);
        setChapters((prev) => prev.map((c) => (c.id === editing.id ? { ...c, ...updated } : c)).sort((a, b) => a.order_index - b.order_index));
        message.success("แก้ไข Chapter แล้ว");
      } else {
        const created = await createQuestChapter(values);
        setChapters((prev) => [...prev, created].sort((a, b) => a.order_index - b.order_index));
        message.success("สร้าง Chapter แล้ว");
      }
      setModalOpen(false);
    } catch (err) {
      if ((err as { errorFields?: unknown })?.errorFields) return;
      message.error("บันทึกไม่สำเร็จ");
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteQuestChapter(id);
      setChapters((prev) => prev.filter((c) => c.id !== id));
      message.success("ลบ Chapter แล้ว (เควสในนั้นจะไม่ถูกลบ แต่จะหลุดออกจาก Chapter)");
    } catch {
      message.error("ลบไม่สำเร็จ (ต้องเป็น admin เท่านั้น)");
    }
  };

  const columns: ColumnsType<AdminQuestChapter> = [
    { title: "ลำดับ", dataIndex: "order_index", key: "order_index", width: 80 },
    { title: "ชื่อ Chapter", dataIndex: "title", key: "title" },
    { title: "รายละเอียด", dataIndex: "description", key: "description", render: (v) => v ?? "-" },
    { title: "จำนวนเควส", dataIndex: "quest_count", key: "quest_count", width: 100 },
    {
      title: "",
      key: "actions",
      width: 150,
      render: (_, chapter) => (
        <Space>
          <Button size="small" onClick={() => openEdit(chapter)}>
            แก้ไข
          </Button>
          <Popconfirm title="ลบ Chapter นี้ถาวร?" onConfirm={() => handleDelete(chapter.id)} okText="ลบ" cancelText="ยกเลิก">
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
          + สร้าง Chapter
        </Button>
      </Space>
      <Table rowKey="id" columns={columns} dataSource={chapters} loading={isLoading} pagination={{ pageSize: 20 }} />
      <Modal
        title={editing ? "แก้ไข Chapter" : "สร้าง Chapter ใหม่"}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText="บันทึก"
        cancelText="ยกเลิก"
        destroyOnHidden
      >
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="ชื่อ Chapter" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="description" label="รายละเอียด">
            <Input.TextArea rows={2} />
          </Form.Item>
          <Form.Item
            name="orderIndex"
            label="ลำดับ Chapter"
            rules={[{ required: true }]}
            help="Chapter จะปลดล็อคตามลำดับนี้ — ต้องทำเควสสุดท้ายของ Chapter ก่อนหน้าให้จบก่อน"
          >
            <InputNumber min={1} style={{ width: "100%" }} />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
}
