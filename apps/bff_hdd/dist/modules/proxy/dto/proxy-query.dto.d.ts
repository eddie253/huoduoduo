export declare class ProxyAreaQueryDto {
    area: string;
}
export declare class ProxyKpiQueryDto extends ProxyAreaQueryDto {
    year: string;
    month: string;
}
export declare class ProxyKpiDailyQueryDto extends ProxyAreaQueryDto {
    date: string;
}
