import { DriverLocationDto } from './dto/driver-location.dto';
import { DriverLocationService } from './driver-location.service';
export declare class DriverLocationController {
    private readonly driverLocationService;
    constructor(driverLocationService: DriverLocationService);
    submitLocation(dto: DriverLocationDto): Promise<{
        ok: boolean;
    }>;
    submitLocationsBatch(dtts: DriverLocationDto[]): Promise<{
        ok: boolean;
    }>;
}
