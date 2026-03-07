import type { Request } from 'express';
import { OrdersService } from './orders.service';
export declare class OrdersController {
    private readonly ordersService;
    constructor(ordersService: OrdersService);
    acceptOrder(request: Request, trackingNo: string, idempotencyKey: string): Promise<{
        ok: boolean;
    }>;
}
