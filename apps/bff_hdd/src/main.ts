import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { LegacySoapExceptionFilter } from './security/legacy-soap-exception.filter';

export async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { cors: true });

  app.use(
    helmet({
      contentSecurityPolicy: false,
      crossOriginEmbedderPolicy: false
    })
  );

  app.setGlobalPrefix('v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true
    })
  );
  app.useGlobalFilters(new LegacySoapExceptionFilter());

  const port = Number(process.env.PORT || 3000);
  await app.listen(port);
}

if (process.env.NODE_ENV !== 'test') {
  void bootstrap();
}
