mod "oci-powerpipe-diff-mod" {
  title = "Powerpipe mod to run diff between 2 OCI compliance reports"
}

dashboard "oci_compliance_diff_report" {
    title = "OCI compliance diff report"
    container{
        input "run_id_1" {
          title = "Select first RunID:"
          width = 3
          sql = query.distinct_run_id.sql
          type = "select"
        }
        input "run_id_2" {
          title = "Select Next RunID:"
          width = 3
          type = "select"
          sql = query.distinct_run_id.sql
        }
    }
    container{
        table{
            title = "Stats for the first run"
            width = 3
            query = query.stats_per_run_id
            args = {"run_id" = self.input.run_id_1.value}
        }
        chart {
            width = 3
            type = "bar"
            query = query.stats_per_run_id
            args = {"run_id" = self.input.run_id_1.value}
        }
        table{
            title = "Stats for the next run"
            width = 3
            query = query.stats_per_run_id
            args = {"run_id" = self.input.run_id_2.value}
        }
        chart {
            width = 3
            type = "column"
            query = query.stats_per_run_id
            args = {"run_id" = self.input.run_id_2.value}
        }
    }

    container{
        table{
            title = "Resolved issues"
            query = query.resolved_issues
            args = {"run_id_1" = self.input.run_id_1.value,"run_id_2" = self.input.run_id_2.value,}
            column "reason"{
              wrap = "all"
            }
            column "control_title"{
              wrap = "all"
            }
            column "resource"{
              wrap = "all"
            }
        }

        table{
            title = "New issues"
            query = query.new_issues
            args = {"run_id_1" = self.input.run_id_1.value,"run_id_2" = self.input.run_id_2.value,}
            column "reason"{
              wrap = "all"
            }
            column "control_title"{
              wrap = "all"
            }
            column "resource"{
              wrap = "all"
            }
        }

        table{
            title = "Unresolved issues"
            query = query.unresolved_issues
            args = {"run_id_1" = self.input.run_id_1.value,"run_id_2" = self.input.run_id_2.value,}
            column "reason"{
              wrap = "all"
            }
            column "title"{
              wrap = "all"
            }
            column "control_title"{
              wrap = "all"
            }
            column "resource"{
              wrap = "all"
            }
        }
    }

}

query "distinct_run_id" {
    sql = <<-EOQ
       select distinct run_id as label,  run_id as value from public.report
    EOQ
}

query "stats_per_run_id" {
    sql = "select status,count(*) from public.report where run_id = $1 group by status ;"
    param "run_id" {}
}

query "resolved_issues" {
     sql = <<-EOQ
         select run_id,
         title,
         control_title,
         reason,
         status,
         resource,cis_type
         from report
         where run_id  = $1 and status in ('alarm','error')
         and (resource,status,cis_item_id) in ( select resource,status,cis_item_id from  report where run_id=$2 and status = 'ok');
     EOQ
     param "run_id_1" {}
     param "run_id_2" {}
}

query "new_issues" {
     sql = <<-EOQ
         select run_id,
         title,
         control_title,
         reason,
         status,
         resource,cis_type
         from report
         where run_id  = $2   and status in ('alarm','error')
         and (resource,status,cis_item_id) not in ( select resource,status,cis_item_id from  report where run_id=$1);
     EOQ
     param "run_id_1" {}
     param "run_id_2" {}
}

query "unresolved_issues" {
     sql = <<-EOQ
         select run_id,
         title,
         control_title,
         reason,
         status,
         resource,cis_type
         from report
         where run_id  = $1 and status in ('alarm','error')
         and (resource,status,cis_item_id) in ( select resource,status,cis_item_id from  report where run_id=$2 and status != 'ok');
     EOQ
     param "run_id_1" {}
     param "run_id_2" {}
}