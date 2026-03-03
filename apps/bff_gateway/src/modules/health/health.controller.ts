import { Controller, Get } from '@nestjs/common';
import { enforceHealthResponseContract } from '../../core/contracts/p4-contract-policy';
import { Public } from '../../security/public.decorator';

@Controller('health')
export class HealthController {
  @Public()
  @Get()
  getHealth(): { status: string; service: string; timestamp: string } {
    return enforceHealthResponseContract({
      status: 'ok',
      service: 'bff_gateway',
      timestamp: new Date().toISOString()
    });
  }
}
