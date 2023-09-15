import { importTypes } from '@rancher/auto-import';
import { IPlugin, CardLocation } from '@shell/core/types';

// Init the package
export default function(plugin: IPlugin) {
  // Auto-import model, detail, edit from the folders
  importTypes(plugin);

  // Provide extension metadata from package.json
  plugin.metadata = require('./package.json');

  // CLUSTER DASHBOARD CARD
  plugin.addCard(
    CardLocation.CLUSTER_DASHBOARD_CARD,
    { cluster: ['local'] },
    {
      label:     'services',
      labelKey:  'services.card-title',
      component: () => import('./components/ServicesDashboardCard.vue')
    }
  );
}
