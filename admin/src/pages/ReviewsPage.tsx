import { useCallback, useEffect, useState } from "react";
import { Button, message, Popconfirm, Rate, Table } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import { deleteReview, fetchReviews } from "../api/admin";
import type { AdminReview } from "../api/types";

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<AdminReview[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      setReviews(await fetchReviews());
    } catch {
      message.error("โหลดรีวิวไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleDelete = async (id: string) => {
    try {
      await deleteReview(id);
      setReviews((prev) => prev.filter((r) => r.id !== id));
      message.success("ลบรีวิวแล้ว");
    } catch {
      message.error("ลบไม่สำเร็จ");
    }
  };

  const columns: ColumnsType<AdminReview> = [
    { title: "จุด (Pin)", dataIndex: "pin_name", key: "pin_name" },
    { title: "ผู้รีวิว", dataIndex: "user_display_name", key: "user_display_name" },
    { title: "คะแนน", dataIndex: "rating", key: "rating", width: 140, render: (v: number) => <Rate disabled value={v} /> },
    { title: "ความเห็น", dataIndex: "comment", key: "comment", render: (v: string | null) => v ?? "-" },
    {
      title: "วันที่",
      dataIndex: "created_at",
      key: "created_at",
      width: 130,
      render: (v: string) => dayjs(v).format("D MMM YYYY"),
    },
    {
      title: "",
      key: "actions",
      width: 90,
      render: (_, review) => (
        <Popconfirm title="ลบรีวิวนี้?" onConfirm={() => handleDelete(review.id)} okText="ลบ" cancelText="ยกเลิก">
          <Button danger size="small">
            ลบ
          </Button>
        </Popconfirm>
      ),
    },
  ];

  return <Table rowKey="id" columns={columns} dataSource={reviews} loading={isLoading} pagination={{ pageSize: 20 }} />;
}
