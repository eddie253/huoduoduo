import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { WebviewController } from './webview.controller';
import { WebviewService } from './webview.service';

@Module({
  imports: [AuthModule],
  controllers: [WebviewController],
  providers: [WebviewService]
})
export class WebviewModule {}
