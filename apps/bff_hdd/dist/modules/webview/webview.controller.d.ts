import type { Request } from 'express';
import { WebviewBootstrapDto } from '../auth/dto/auth-response.dto';
import { BulletinDto, WebviewService } from './webview.service';
export declare class WebviewController {
    private readonly webviewService;
    constructor(webviewService: WebviewService);
    getWebviewBootstrap(request: Request): Promise<WebviewBootstrapDto>;
    getCurrentBulletin(request: Request): Promise<BulletinDto>;
}
