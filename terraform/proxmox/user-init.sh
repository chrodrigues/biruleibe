#!/bin/bash

#TODO: needs to be solved: Error: environment: line 1: pvesm: command not found

pveum role add terraform -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Datastore.Allocate Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

pveum user add terraform@pam --password gUBainzcDqksmYdZ

pveum aclmod / -user terraform@pam -role terraform


