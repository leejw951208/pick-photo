import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupOpenApi } from './openapi';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  setupOpenApi(app);
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
