import { useCallback, useEffect, useState } from "react";
import { Input, message, Space, Table } from "antd";
import type { ColumnsType } from "antd/es/table";
import { fetchEmergencyContacts } from "../api/admin";
import type { AdminEmergencyContact } from "../api/types";

export default function EmergencyContactsPage() {
  const [contacts, setContacts] = useState<AdminEmergencyContact[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState("");

  const load = useCallback(async (searchTerm?: string) => {
    setIsLoading(true);
    try {
      setContacts(await fetchEmergencyContacts(searchTerm));
    } catch {
      message.error("โหลดข้อมูลผู้ติดต่อฉุกเฉินไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const columns: ColumnsType<AdminEmergencyContact> = [
    { title: "ผู้ใช้", dataIndex: "display_name", key: "display_name" },
    { title: "อีเมลผู้ใช้", dataIndex: "email", key: "email" },
    { title: "ชื่อผู้ติดต่อฉุกเฉิน", dataIndex: "emergency_contact_name", key: "emergency_contact_name" },
    { title: "เบอร์โทรผู้ติดต่อฉุกเฉิน", dataIndex: "emergency_contact_phone", key: "emergency_contact_phone" },
  ];

  return (
    <>
      <Space style={{ marginBottom: 16 }}>
        <Input.Search
          placeholder="ค้นหาชื่อหรืออีเมลผู้ใช้"
          allowClear
          style={{ width: 280 }}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onSearch={(value) => load(value)}
        />
      </Space>
      <Table rowKey="id" columns={columns} dataSource={contacts} loading={isLoading} pagination={{ pageSize: 20 }} />
    </>
  );
}
