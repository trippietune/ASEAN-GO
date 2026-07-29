export const COIN_PACKAGES = {
  small: { coins: 30, priceThb: 30 },
  medium: { coins: 150, priceThb: 129 },
  large: { coins: 500, priceThb: 399 },
  xl: { coins: 1200, priceThb: 699 },
} as const;

export type PackageId = keyof typeof COIN_PACKAGES;

export function isPackageId(value: string): value is PackageId {
  return value in COIN_PACKAGES;
}

/// Omise amounts are in satang (1 THB = 100 satang), matching how every
/// other Thai payment gateway represents THB.
export function thbToSatang(thb: number): number {
  return thb * 100;
}
