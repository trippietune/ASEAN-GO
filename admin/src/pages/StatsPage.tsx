import { useEffect, useState } from "react";
import { Alert, Card, Col, Row, Spin, Statistic } from "antd";
import {
  TeamOutlined,
  EnvironmentOutlined,
  TrophyOutlined,
  StarOutlined,
  AlertOutlined,
  WarningOutlined,
  ExclamationCircleOutlined,
} from "@ant-design/icons";
import { fetchStats } from "../api/admin";
import type { AdminStats } from "../api/types";

export default function StatsPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchStats()
      .then(setStats)
      .catch(() => setError("โหลดสถิติไม่สำเร็จ"))
      .finally(() => setIsLoading(false));
  }, []);

  if (isLoading) return <Spin size="large" />;
  if (error || !stats) return <Alert type="error" message={error ?? "ไม่มีข้อมูล"} showIcon />;

  return (
    <Row gutter={[16, 16]}>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic
            title="ผู้ใช้ทั้งหมด"
            value={stats.users.total}
            prefix={<TeamOutlined />}
            suffix={<span style={{ fontSize: 14, color: "#888" }}>+{stats.users.new_this_week} สัปดาห์นี้</span>}
          />
        </Card>
      </Col>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic
            title="Pins ทั้งหมด"
            value={stats.pins.total}
            prefix={<EnvironmentOutlined />}
            suffix={<span style={{ fontSize: 14, color: "#888" }}>{stats.pins.verified} ยืนยันแล้ว</span>}
          />
        </Card>
      </Col>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic title="Quests ทั้งหมด" value={stats.quests.total} prefix={<TrophyOutlined />} />
        </Card>
      </Col>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic
            title="รีวิวทั้งหมด"
            value={stats.reviews.total}
            precision={0}
            prefix={<StarOutlined />}
            suffix={<span style={{ fontSize: 14, color: "#888" }}>เฉลี่ย {stats.reviews.average_rating.toFixed(1)}</span>}
          />
        </Card>
      </Col>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic
            title="SOS ที่กำลังทำงาน"
            value={stats.activeSosEvents}
            prefix={<AlertOutlined />}
            valueStyle={{ color: stats.activeSosEvents > 0 ? "#cf1322" : undefined }}
          />
        </Card>
      </Col>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic title="รายงานพื้นที่เสี่ยง" value={stats.riskReports} prefix={<WarningOutlined />} />
        </Card>
      </Col>
      <Col xs={24} sm={12} lg={8}>
        <Card>
          <Statistic
            title="Scam Alert ที่ตั้งค่าไว้"
            value={stats.scamAlerts}
            prefix={<ExclamationCircleOutlined />}
            valueStyle={{ color: stats.scamAlerts > 0 ? "#d46b08" : undefined }}
          />
        </Card>
      </Col>
    </Row>
  );
}
