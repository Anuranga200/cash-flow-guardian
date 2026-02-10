import { useNavigate } from 'react-router-dom';
import { PageHeader } from '@/components/layout/PageHeader';
import { suppliers } from '@/data/mockData';
import { ChevronRight, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function SuppliersPage() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background">
      <PageHeader
        title="Suppliers"
        rightAction={
          <Button size="sm" className="gap-1 bg-accent text-accent-foreground hover:bg-accent/90">
            <Plus className="h-4 w-4" /> Add
          </Button>
        }
      />
      <div className="page-container space-y-2">
        {suppliers.map((supplier) => (
          <button
            key={supplier.id}
            onClick={() => navigate(`/suppliers/${supplier.id}`)}
            className="flex w-full items-center gap-3 rounded-xl bg-card p-4 text-left shadow-sm border border-border/50 transition-all hover:shadow-md"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary font-bold text-sm shrink-0">
              {supplier.company.charAt(0)}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-card-foreground truncate">{supplier.company}</p>
              <p className="text-xs text-muted-foreground">{supplier.contactPerson} · {supplier.paymentTermsDays} day terms</p>
            </div>
            <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0" />
          </button>
        ))}
      </div>
    </div>
  );
}
