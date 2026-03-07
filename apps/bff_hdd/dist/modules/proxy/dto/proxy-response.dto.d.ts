export declare class ProxyMateItemDto {
    code: string;
    name: string;
    area: string | null;
    status: string | null;
    service: string | null;
    role: string | null;
    message: string | null;
    updatedAt: string | null;
}
export declare class ProxyKpiItemDto {
    code: string;
    name: string;
    status: string | null;
    service: string | null;
    role: string | null;
    message: string | null;
    updatedAt: string | null;
}
export declare class ProxyMateListResponseDto {
    items: ProxyMateItemDto[];
}
export declare class ProxyKpiListResponseDto {
    items: ProxyKpiItemDto[];
}
