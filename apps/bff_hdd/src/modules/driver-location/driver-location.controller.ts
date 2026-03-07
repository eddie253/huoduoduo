import { Body, Controller, ParseArrayPipe, Post } from '@nestjs/common';
import { DriverLocationDto } from './dto/driver-location.dto';
import { DriverLocationService } from './driver-location.service';

@Controller('drivers/location')
export class DriverLocationController {
  constructor(private readonly driverLocationService: DriverLocationService) {}

  @Post()
  submitLocation(@Body() dto: DriverLocationDto): Promise<{ ok: boolean }> {
    return this.driverLocationService.submitLocation(dto);
  }

  @Post('batch')
  submitLocationsBatch(
    @Body(
      new ParseArrayPipe({
        items: DriverLocationDto,
        whitelist: true,
        forbidNonWhitelisted: true
      })
    )
    dtts: DriverLocationDto[]
  ): Promise<{ ok: boolean }> {
    return this.driverLocationService.submitLocationsBatch(dtts);
  }
}
