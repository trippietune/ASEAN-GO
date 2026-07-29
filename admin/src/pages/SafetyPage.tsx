import { useCallback, useEffect, useState } from "react";
import { Button, message, Popconfirm, Segmented, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import { deleteRiskReport, fetchRiskReports, fetchSosEvents, resolveSosEvent } from "../api/admin";
import type { AdminRiskReport, AdminSosEvent, RiskSeverity } from "../api/types";

const SEVERITY_COLORS: Record<RiskSeverity, string> = { caution: "gold", warning: "orange", danger: "red" };

function RiskReportsTab() {
  const [reports, setReports] = useState<AdminRiskReport[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      setReports(await fetchRiskReports());
    } catch {
      message.error("โหลดรายงานพื้นที่เสี่ยงไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleDelete = async (id: string) => {
    try {
      await deleteRiskReport(id);
      setReports((prev) => prev.filter((r) => r.id !== id));
      message.success("ลบรายงานแล้ว");
    } catch {
      message.error("ลบไม่สำเร็จ");
    }
  };

  const columns: ColumnsType<AdminRiskReport> = [
    { title: "จุด (Pin)", dataIndex: "pin_name", key: "pin_name" },
    { title: "ผู้รายงาน", dataIndex: "reporter_display_name", key: "reporter_display_name" },
    {
      title: "ระดับ",
      dataIndex: "severity",
      key: "severity",
      width: 110,
      render: (severity: RiskSeverity) => <Tag color={SEVERITY_COLORS[severity]}>{severity}</Tag>,
    },
    { title: "รายละเอียด", dataIndex: "description", key: "description" },
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
      render: (_, report) => (
        <Popconfirm title="ลบรายงานนี้?" onConfirm={() => handleDelete(report.id)} okText="ลบ" cancelText="ยกเลิก">
          <Button danger size="small">
            ลบ
          </Button>
        </Popconfirm>
      ),
    },
  ];

  return <Table rowKey="id" columns={columns} dataSource={reports} loading={isLoading} pagination={{ pageSize: 20 }} />;
}

function SosEventsTab() {
  const [events, setEvents] = useState<AdminSosEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<"all" | "active" | "resolved">("active");

  const load = useCallback(async (status: "all" | "active" | "resolved") => {
    setIsLoading(true);
    try {
      setEvents(await fetchSosEvents(status === "all" ? undefined : status));
    } catch {
      message.error("โหลดเหตุการณ์ SOS ไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load(statusFilter);
  }, [load, statusFilter]);

  const handleResolve = async (id: string) => {
    try {
      await resolveSosEvent(id);
      message.success("ปิดเหตุการณ์ SOS แล้ว");
      load(statusFilter);
    } catch {
      message.error("ดำเนินการไม่สำเร็จ");
    }
  };

  const columns: ColumnsType<AdminSosEvent> = [
    { title: "ผู้ใช้", dataIndex: "user_display_name", key: "user_display_name" },
    {
      title: "ผู้ติดต่อฉุกเฉิน",
      key: "emergency_contact",
      render: (_, ev) =>
        ev.emergency_contact_name ? `${ev.emergency_contact_name} (${ev.emergency_contact_phone})` : "ยังไม่ตั้งค่า",
    },
    {
      title: "พิกัด",
      key: "location",
      render: (_, ev) => `${ev.lat.toFixed(5)}, ${ev.lng.toFixed(5)}`,
    },
    {
      title: "สถานะ",
      dataIndex: "status",
      key: "status",
      width: 100,
      render: (status: string) => <Tag color={status === "active" ? "red" : "green"}>{status}</Tag>,
    },
    {
      title: "เวลาแจ้ง",
      dataIndex: "created_at",
      key: "created_at",
      width: 160,
      render: (v: string) => dayjs(v).format("D MMM YYYY HH:mm"),
    },
    {
      title: "",
      key: "actions",
      width: 110,
      render: (_, ev) =>
        ev.status === "active" ? (
          <Popconfirm title="ยืนยันว่าปลอดภัยแล้ว?" onConfirm={() => handleResolve(ev.id)} okText="ปิดเหตุการณ์" cancelText="ยกเลิก">
            <Button size="small" type="primary">
              ปิดเหตุการณ์
            </Button>
          </Popconfirm>
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
          { label: "กำลังทำงาน", value: "active" },
          { label: "ปิดแล้ว", value: "resolved" },
          { label: "ทั้งหมด", value: "all" },
        ]}
      />
      <Table rowKey="id" columns={columns} dataSource={events} loading={isLoading} pagination={{ pageSize: 20 }} />
    </>
  );
}

export default function SafetyPage() {
  const [tab, setTab] = useState<"sos" | "risk-reports">("sos");

  return (
    <>
      <Segmented
        style={{ marginBottom: 16 }}
        value={tab}
        onChange={(v) => setTab(v as typeof tab)}
        options={[
          { label: "เหตุการณ์ SOS", value: "sos" },
          { label: "รายงานพื้นที่เสี่ยง", value: "risk-reports" },
        ]}
      />
      {tab === "sos" ? <SosEventsTab /> : <RiskReportsTab />}
    </>
  );
}
