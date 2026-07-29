import { useCallback, useEffect, useState } from "react";
import { Button, InputNumber, message, Modal, Segmented, Table, Tag } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import { fetchPaymentTransactions, refundPaymentTransaction } from "../api/admin";
import type { AdminPaymentTransaction, PaymentStatus } from "../api/types";

const STATUS_COLORS: Record<PaymentStatus, string> = {
  pending: "gold",
  successful: "green",
  failed: "red",
  refunded: "default",
  partially_refunded: "orange",
};

function thb(satang: number): string {
  return `฿${(satang / 100).toFixed(2)}`;
}

export default function PaymentsPage() {
  const [transactions, setTransactions] = useState<AdminPaymentTransaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<PaymentStatus | "all">("all");
  const [refundTarget, setRefundTarget] = useState<AdminPaymentTransaction | null>(null);
  const [refundAmount, setRefundAmount] = useState<number | null>(null);
  const [isRefunding, setIsRefunding] = useState(false);

  const load = useCallback(async (status: PaymentStatus | "all") => {
    setIsLoading(true);
    try {
      setTransactions(await fetchPaymentTransactions(status === "all" ? undefined : status));
    } catch {
      message.error("โหลดรายการชำระเงินไม่สำเร็จ");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load(statusFilter);
  }, [load, statusFilter]);

  const openRefund = (tx: AdminPaymentTransaction) => {
    const remainingThb = (tx.amount_thb - tx.refunded_amount_thb) / 100;
    setRefundTarget(tx);
    setRefundAmount(remainingThb);
  };

  const submitRefund = async () => {
    if (!refundTarget || !refundAmount) return;
    setIsRefunding(true);
    try {
      const result = await refundPaymentTransaction(refundTarget.id, refundAmount);
      message.success(
        `คืนเงินสำเร็จ ${result.refundedAmountThb} บาท` +
          (result.coinsClawedBack > 0 ? ` และดึงเหรียญคืน ${result.coinsClawedBack} เหรียญ` : "")
      );
      setRefundTarget(null);
      load(statusFilter);
    } catch (err) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error ?? "คืนเงินไม่สำเร็จ";
      message.error(msg);
    } finally {
      setIsRefunding(false);
    }
  };

  const columns: ColumnsType<AdminPaymentTransaction> = [
    { title: "ผู้ใช้", dataIndex: "user_display_name", key: "user_display_name" },
    { title: "แพ็กเกจ", dataIndex: "package_id", key: "package_id", width: 100 },
    { title: "เหรียญ", dataIndex: "coins", key: "coins", width: 80 },
    { title: "จำนวนเงิน", key: "amount", width: 110, render: (_, tx) => thb(tx.amount_thb) },
    {
      title: "สถานะ",
      dataIndex: "status",
      key: "status",
      width: 140,
      render: (status: PaymentStatus) => <Tag color={STATUS_COLORS[status]}>{status}</Tag>,
    },
    {
      title: "คืนเงินแล้ว",
      dataIndex: "refunded_amount_thb",
      key: "refunded_amount_thb",
      width: 110,
      render: (v: number) => (v > 0 ? thb(v) : "-"),
    },
    {
      title: "Charge ID",
      dataIndex: "provider_charge_id",
      key: "provider_charge_id",
      render: (v: string | null) => v ?? "-",
    },
    {
      title: "สาเหตุที่ล้มเหลว",
      dataIndex: "failure_message",
      key: "failure_message",
      render: (v: string | null) => v ?? "-",
    },
    {
      title: "วันที่",
      dataIndex: "created_at",
      key: "created_at",
      width: 160,
      render: (v: string) => dayjs(v).format("D MMM YYYY HH:mm"),
    },
    {
      title: "",
      key: "actions",
      width: 100,
      render: (_, tx) =>
        tx.status === "successful" || tx.status === "partially_refunded" ? (
          <Button size="small" onClick={() => openRefund(tx)}>
            คืนเงิน
          </Button>
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
          { label: "ทั้งหมด", value: "all" },
          { label: "สำเร็จ", value: "successful" },
          { label: "รอดำเนินการ", value: "pending" },
          { label: "ล้มเหลว", value: "failed" },
          { label: "คืนเงินแล้ว", value: "refunded" },
        ]}
      />
      <Table rowKey="id" columns={columns} dataSource={transactions} loading={isLoading} pagination={{ pageSize: 20 }} scroll={{ x: 1200 }} />
      <Modal
        title={`คืนเงิน: ${refundTarget?.user_display_name ?? ""}`}
        open={refundTarget !== null}
        onOk={submitRefund}
        onCancel={() => setRefundTarget(null)}
        okText="ยืนยันคืนเงิน"
        cancelText="ยกเลิก"
        confirmLoading={isRefunding}
      >
        {refundTarget && (
          <>
            <p>
              ยอดที่คืนได้สูงสุด: {thb(refundTarget.amount_thb - refundTarget.refunded_amount_thb)}
            </p>
            <InputNumber
              style={{ width: "100%" }}
              min={1}
              max={(refundTarget.amount_thb - refundTarget.refunded_amount_thb) / 100}
              value={refundAmount ?? undefined}
              onChange={(v) => setRefundAmount(v)}
              addonAfter="บาท"
            />
          </>
        )}
      </Modal>
    </>
  );
}
