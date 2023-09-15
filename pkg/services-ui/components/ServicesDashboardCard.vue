<script>
import SortableTable from '@shell/components/SortableTable';
import { SERVICE } from '@shell/config/types';

const VERSION = '0.1.0';

export default {
  name:       'ServicesDashboardCard',
  components: { SortableTable },
  props:      {
    resource: {
      type:     Object,
      required: true
    }
  },
  async fetch() {
    await this.fetchDeps();
  },
  data() {
    const gpuCardIconSrc = require('@pkg/services-ui/icons/gpu-card.svg');
    const gearIconSrc = require('@pkg/services-ui/icons/gear.svg');

    return {
      version:        VERSION,
      icons:   {
        'gpu-card': gpuCardIconSrc,
        gear:       gearIconSrc
      },
      externalLinks:   [],
      showBrokenLinks: false,
      tableHeaders:    [
        {
          name:          'namespace',
          label:         'Namespace',
          value:         'namespace'
        },
        {
          name:          'name',
          label:         'Name',
          value:         'name'
        },
        {
          name:          'description',
          label:         'Description',
          value:         'description'
        },
      ]
    };
  },
  methods: {

    async fetchDeps() {
      const { icons, externalLinks } = this;

      const currentCluster = this.$store.getters['currentCluster'];
      const inStore = this.$store.getters['currentProduct'].inStore;
      const services = await this.$store.dispatch(`${ inStore }/findAll`, { type: SERVICE });

      // console.log('SERVICES::');

      for (const serviceIndex in services) {
        const service = services[serviceIndex];
        const serviceName = service.metadata.name;
        const serviceNamespace = service.metadata.namespace;

        // console.log(`Check ${ serviceIndex }-th service ${ serviceNamespace }/${ serviceName }`);
        // console.log(service);

        for (const port of service.spec.ports) {
          if (port.protocol !== 'TCP') {
            continue;
          }

          const portName = port.name ?? '';
          const portNum = port.port ?? 0;

          if (portNum <= 0) {
            continue;
          }

          let isHttps = portName.includes('https');
          let isHttp = portName.includes('http') && !isHttps;

          if (!isHttp && !isHttps) {
            switch (portNum) {
            case 80:
            case 8080:
              isHttp = true;
              break;
            case 443:
            case 8443:
            case 6443:
              isHttps = true;
              break;
            }
          }

          if (!isHttp && !isHttps) {
            continue;
          }

          await service.fetchPods();

          const servicePort = portNum;
          const serviceProtocol = isHttp ? 'http' : 'https';
          const serviceDescription = isHttp ? `HTTP service on port ${ portNum }` : `HTTPS service on port ${ portNum }`;
          const serviceId = `${ serviceNamespace }/${ serviceName }:${ portNum }`;

          const serviceLink = `/k8s/clusters/${ currentCluster.id }/api/v1/namespaces/${ serviceNamespace }/services/${ serviceProtocol }:${ serviceName }:${ servicePort }/proxy`;

          let serviceLinkEnabled = true;
          let serviceLinkStatus = '';

          if (service.pods.length === 0) {
            serviceLinkEnabled = false;
            serviceLinkStatus = 'No endpoint pods';
          } else {
            try {
              const response = await this.$axios.get(serviceLink, { timeout: 5000 });

              serviceLinkEnabled = response && response.status === 200;

              if (response) {
                if (response.status !== 200) {
                  serviceLinkStatus = `Could not get link, status code: ${ response.status.toString() }`;
                }
              } else {
                serviceLinkStatus = 'Could not get link, no status code';
              }
            } catch (e) {
              serviceLinkEnabled = false;
              serviceLinkStatus = `Could not get link: ${ e.toString() }`;
            }
          }

          externalLinks.push({
            enabled:     serviceLinkEnabled,
            iconSrc:     icons.gear,
            kind:        'service',
            namespace:   serviceNamespace,
            name:        serviceName,
            description: serviceDescription,
            id:          serviceId,
            link:        serviceLink,
            status:      serviceLinkStatus
          });
        }
      }
    },

    toggleShowBrokenLinks() {
      this.showBrokenLinks = !this.showBrokenLinks;
    }
  },
  computed: {
    serviceLinks() {
      return this.externalLinks.filter(link => link.enabled || this.showBrokenLinks);
    },
    toggleShowBrokenLinksButtonName() {
      return this.showBrokenLinks ? this.t('services.list.hide-broken-links') : this.t('services.list.show-broken-links');
    }
  }
};
</script>
<template>
  <div>
    <SortableTable
      :rows="serviceLinks"
      :headers="tableHeaders"
      key-field="id"
      :table-actions="false"
      :search="true"
    >
      <template #header-middle>
        <button
          type="button"
          class="btn btn-sm role-secondary"
          :disabled="false"
          @click="toggleShowBrokenLinks()"
        >
          {{ toggleShowBrokenLinksButtonName }}
        </button>
      </template>
      <template #col:name="{row}">
        <td v-if="row.enabled">
          <a
            v-clean-tooltip="!row.enabled ? t('services.list.na') : undefined"
            :href="row.link"
            target="_blank"
            rel="noopener noreferrer"
            :class="{ disabled: !row.enabled }"
          ><div class="flex-right">
            {{ row.name }}
          </div>
          </a>
        </td>
        <td v-else>
          <div class="flex-right">
            {{ row.name }}
          </div>
          <div class="bg-error">
            {{ row.status }}
          </div>
        </td>
      </template>
    </SortableTable>
  </div>
</template>

<style lang="scss" scoped>
  .create-resource-container .subtype-banner {
    min-height: 80px;
    padding: 10px;
  }
</style>
