import { PageHeader } from '@/components/layout/PageHeader';
import { notifications } from '@/data/mockData';
import { Bell, Mail } from 'lucide-react';

export default function NotificationsPage() {
  return (
    <div className="min-h-screen bg-background">
      <PageHeader title="Notifications" showBack />
      <div className="page-container space-y-2">
        {notifications.map((notif) => (
          <div
            key={notif.id}
            className={`rounded-xl border p-4 transition-colors ${
              notif.read
                ? 'border-border/50 bg-card'
                : 'border-accent/30 bg-accent/5'
            }`}
          >
            <div className="flex items-start gap-3">
              <div className={`mt-0.5 flex h-8 w-8 items-center justify-center rounded-full shrink-0 ${
                notif.type === 'email' ? 'bg-info/10' : 'bg-warning/10'
              }`}>
                {notif.type === 'email' ? (
                  <Mail className="h-4 w-4 text-info" />
                ) : (
                  <Bell className="h-4 w-4 text-warning" />
                )}
              </div>
              <div className="min-w-0">
                <p className={`text-sm ${notif.read ? 'text-card-foreground' : 'font-semibold text-card-foreground'}`}>
                  {notif.message}
                </p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {new Date(notif.dateSent).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                  {' · '}
                  <span className="capitalize">{notif.type}</span>
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
