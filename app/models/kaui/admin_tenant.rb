class Kaui::AdminTenant < KillBillClient::Model::Tenant


  class << self
    def upload_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})
      KillBillClient::Model::Catalog.upload_tenant_catalog(catalog_xml, user, reason, comment, options)
    end

    def upload_overdue_config(overdue_config_xml, user = nil, reason = nil, comment = nil, options = {})
      KillBillClient::Model::Overdue.upload_tenant_overdue_config(overdue_config_xml, user, reason, comment, options)
    end

  end

end