import { useMemo } from "react";
import { Layout, Menu, Typography, Avatar, Dropdown, Tag } from "antd";
import {
  DashboardOutlined,
  EnvironmentOutlined,
  FileSearchOutlined,
  TrophyOutlined,
  TeamOutlined,
  StarOutlined,
  SafetyOutlined,
  PhoneOutlined,
  CreditCardOutlined,
  LogoutOutlined,
  BookOutlined,
  GiftOutlined,
} from "@ant-design/icons";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

const { Header, Sider, Content } = Layout;

const NAV_ITEMS = [
  { key: "/", icon: <DashboardOutlined />, label: "ภาพรวม" },
  { key: "/pins", icon: <EnvironmentOutlined />, label: "Pins" },
  { key: "/pin-suggestions", icon: <FileSearchOutlined />, label: "Pin Suggestions" },
  { key: "/quests", icon: <TrophyOutlined />, label: "Quests" },
  { key: "/quest-chapters", icon: <BookOutlined />, label: "Quest Chapters" },
  { key: "/achievements", icon: <GiftOutlined />, label: "Achievements" },
  { key: "/users", icon: <TeamOutlined />, label: "Users" },
  { key: "/reviews", icon: <StarOutlined />, label: "Reviews" },
  { key: "/safety", icon: <SafetyOutlined />, label: "Safety Zones" },
  { key: "/emergency-contacts", icon: <PhoneOutlined />, label: "Emergency Contacts" },
  { key: "/payments", icon: <CreditCardOutlined />, label: "Payments" },
];

export default function AdminLayout() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const selectedKey = useMemo(() => {
    const match = NAV_ITEMS.find((item) => item.key !== "/" && location.pathname.startsWith(item.key));
    return match?.key ?? "/";
  }, [location.pathname]);

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Sider breakpoint="lg" collapsedWidth="0">
        <div style={{ color: "white", fontWeight: 700, fontSize: 18, padding: "16px 20px" }}>ASEAN GO Admin</div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[selectedKey]}
          items={NAV_ITEMS}
          onClick={({ key }) => navigate(key)}
        />
      </Sider>
      <Layout>
        <Header style={{ background: "#fff", display: "flex", alignItems: "center", justifyContent: "flex-end", padding: "0 24px", gap: 12 }}>
          <Tag color={user?.role === "admin" ? "gold" : "blue"}>{user?.role}</Tag>
          <Dropdown
            menu={{
              items: [{ key: "logout", icon: <LogoutOutlined />, label: "ออกจากระบบ", onClick: logout }],
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
              <Avatar src={user?.avatar_url ?? undefined}>{user?.display_name?.charAt(0)}</Avatar>
              <Typography.Text>{user?.display_name}</Typography.Text>
            </div>
          </Dropdown>
        </Header>
        <Content style={{ margin: 24 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
