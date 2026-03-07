import { SystemVersionQueryDto } from './dto/system-version-query.dto';
import { SystemVersionResponseDto } from './dto/system-version-response.dto';
import { SystemService } from './system.service';
export declare class SystemController {
    private readonly systemService;
    constructor(systemService: SystemService);
    getVersion(query: SystemVersionQueryDto): Promise<SystemVersionResponseDto>;
}
