import { ArrowLeft, Bell } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { Badge } from '@/components/ui/badge';

interface PageHeaderProps {
  title: string;
  showBack?: boolean;
  showNotifications?: boolean;
  unreadCount?: number;
  rightAction?: React.ReactNode;
}

export function PageHeader({ title, showBack, showNotifications, unreadCount = 0, rightAction }: PageHeaderProps) {
  const navigate = useNavigate();

  return (
    <header className="sticky top-0 z-40 flex items-center justify-between border-b border-border bg-card/95 px-4 py-3 backdrop-blur-md">
      <div className="flex items-center gap-3">
        {showBack && (
          <button onClick={() => navigate(-1)} className="rounded-lg p-1.5 text-foreground hover:bg-secondary transition-colors">
            <ArrowLeft className="h-5 w-5" />
          </button>
        )}
        <h1 className="text-lg font-bold text-foreground">{title}</h1>
      </div>
      <div className="flex items-center gap-2">
        {rightAction}
        {showNotifications && (
          <button onClick={() => navigate('/notifications')} className="relative rounded-lg p-2 text-muted-foreground hover:bg-secondary transition-colors">
            <Bell className="h-5 w-5" />
            {unreadCount > 0 && (
              <Badge className="absolute -right-0.5 -top-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-destructive p-0 text-[10px] text-destructive-foreground">
                {unreadCount}
              </Badge>
            )}
          </button>
        )}
      </div>
    </header>
  );
}
