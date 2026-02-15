import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
  SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
} from '@opentelemetry/semantic-conventions';

// 環境変数から設定を取得
const serviceName = process.env.OTEL_SERVICE_NAME || 'journaly-backend';
const serviceVersion = process.env.OTEL_SERVICE_VERSION || '1.0.0';
const environment = process.env.NODE_ENV || 'development';
const otlpEndpoint =
  process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

// リソース属性を定義
const resource = new Resource({
  [ATTR_SERVICE_NAME]: serviceName,
  [ATTR_SERVICE_VERSION]: serviceVersion,
  [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: environment,
});

// OTLP HTTPエクスポーターを設定
const traceExporter = new OTLPTraceExporter({
  url: `${otlpEndpoint}/v1/traces`,
});

// NodeSDKを初期化
const sdk = new NodeSDK({
  resource,
  traceExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      // HTTPサーバーとクライアントの自動計測
      '@opentelemetry/instrumentation-http': {
        enabled: true,
      },
      // Expressの自動計測
      '@opentelemetry/instrumentation-express': {
        enabled: true,
      },
    }),
  ],
});

// SDKを開始
try {
  sdk.start();
  console.log(
    `OpenTelemetry initialized: service=${serviceName}, environment=${environment}, endpoint=${otlpEndpoint}`,
  );
} catch (error) {
  console.error('Error initializing OpenTelemetry:', error);
}

// アプリケーション終了時にクリーンアップ
process.on('SIGTERM', () => {
  sdk
    .shutdown()
    .then(() => console.log('OpenTelemetry SDK shut down successfully'))
    .catch((error) =>
      console.error('Error shutting down OpenTelemetry:', error),
    )
    .finally(() => process.exit(0));
});
