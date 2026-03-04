export class ProxyMateItemDto {
  code!: string;
  name!: string;
  area!: string | null;
  status!: string | null;
  service!: string | null;
  role!: string | null;
  message!: string | null;
  updatedAt!: string | null;
}

export class ProxyKpiItemDto {
  code!: string;
  name!: string;
  status!: string | null;
  service!: string | null;
  role!: string | null;
  message!: string | null;
  updatedAt!: string | null;
}

export class ProxyMateListResponseDto {
  items!: ProxyMateItemDto[];
}

export class ProxyKpiListResponseDto {
  items!: ProxyKpiItemDto[];
}
