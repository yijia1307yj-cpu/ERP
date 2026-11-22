import { ConfigProvider, Empty, Layout, theme } from 'antd';
import zhCN from 'antd/locale/zh_CN';

export function App() {
  return (
    <ConfigProvider locale={zhCN} theme={{ algorithm: [theme.compactAlgorithm] }}>
      <Layout style={{ minHeight: '100vh' }}>
        <Layout.Content style={{ padding: 24 }}>
          <Empty />
        </Layout.Content>
      </Layout>
    </ConfigProvider>
  );
}
