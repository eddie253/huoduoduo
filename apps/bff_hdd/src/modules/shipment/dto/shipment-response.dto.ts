export interface ShipmentResponseDto {
  trackingNo: string;
  recipient: string;
  address: string;
  phone: string;
  mobile: string;
  zipCode: string;
  city: string;
  district: string;
  status: string;
  signedAt: string | null;
  signedImageFileName: string | null;
  signedLocation: string | null;
}
