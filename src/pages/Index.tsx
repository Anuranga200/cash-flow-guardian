import { PageHeader } from '@/components/layout/PageHeader';
import { SummaryCards } from '@/components/dashboard/SummaryCards';
import { UpcomingChequesList } from '@/components/dashboard/UpcomingChequesList';
import { MLForecastSection } from '@/components/dashboard/MLForecastSection';
import { notifications } from '@/data/mockData';

const Dashboard = () => {
  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="min-h-screen bg-background">
      <PageHeader title="Dashboard" showNotifications unreadCount={unreadCount} />
      <div className="page-container space-y-6">
        <SummaryCards />
        <UpcomingChequesList />
        <MLForecastSection />
      </div>
    </div>
  );
};

export default Dashboard;
