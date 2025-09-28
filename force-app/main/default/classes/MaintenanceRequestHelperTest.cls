@isTest
public with sharing class MaintenanceRequestHelperTest {
    
    private static final string STATUS_NEW = 'New';    
    private static final string WORKING = 'Working';
    private static final string CLOSED = 'Closed';
    private static final string REPAIR = 'Repair';
    private static final string REQUEST_ORIGIN = 'Web';
    private static final string REQUEST_TYPE = 'Routine Maintenance';
    private static final string REQUEST_SUBJECT = 'Testing subject';

    PRIVATE STATIC Vehicle__c createVehicle(){
        Vehicle__c vehicle = new Vehicle__c(
            Name = 'SuperTruck'
        );
        return vehicle;
    }

    PRIVATE STATIC Product2 createEq(){
        Product2 equipment = new Product2(
            Name = 'SuperEquipment',
            Lifespan_Months__c = 10,
            Maintenance_Cycle__c = 10,
            Replacement_Part__c = true
        );
        return equipment;
    }

    PRIVATE STATIC Case createMaintenanceRequest(Id vehicleId, Id equipmentId){
        Case cs = new Case(
            Type = REPAIR,
            Status = STATUS_NEW,
            Origin = REQUEST_ORIGIN,
            Subject = REQUEST_SUBJECT,
            Vehicle__c = vehicleId,
            Equipment__c = equipmentId
        );
        return cs;
    }

    PRIVATE STATIC Equipment_Maintenance_Item__c createWorkPart(id equipmentId,id requestId){
        Equipment_Maintenance_Item__c wp = new Equipment_Maintenance_Item__c(Equipment__c = equipmentId,
                                                                            Maintenance_Request__c = requestId);
        return wp;
    }

    @isTest
    private static void testMaintenanceRequestPositive(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        id vehicleId = vehicle.Id;

        Product2 equipment = createEq();
        insert equipment;
        id equipmentId = equipment.Id;

        Case somethingToUpdate = createMaintenanceRequest(vehicleId,equipmentId);
        insert somethingToUpdate;

        Equipment_Maintenance_Item__c workP = createWorkPart(equipmentId,somethingToUpdate.Id);
        insert workP;

        test.startTest();
            somethingToUpdate.Status = CLOSED;
            update somethingToUpdate;
        test.stopTest();

        Case newReq = [SELECT Id, Subject, Type, Equipment__c, Date_Reported__C, Vehicle__c, Date_Due__c
                        FROM Case WHERE Status = :STATUS_NEW];

        Equipment_Maintenance_Item__c workPart = [SELECT Id FROM Equipment_Maintenance_Item__c 
                                                    WHERE Maintenance_Request__c = :newReq.Id];
        
        System.assert(workPart != null);
        System.assert(newReq.Subject != null);
        System.assertEquals(newReq.Type, REQUEST_TYPE);
        System.assertEquals(newReq.Equipment__c, equipmentId);
        System.assertEquals(newReq.Vehicle__c, vehicleId);
        System.assertEquals(newReq.Date_Reported__c, Date.today());
    }

    @isTest
    private static void testMaintenanceRequestNegative(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        id vehicleId = vehicle.Id;

        Product2 equipment = createEq();
        insert equipment;
        id equipmentId = equipment.Id;

        Case emptyReq = createMaintenanceRequest(vehicleId,equipmentId);
        insert emptyReq;

        Equipment_Maintenance_Item__c workP = createWorkPart(equipmentId,emptyReq.Id);
        insert workP;

        test.startTest();
            emptyReq.Status = WORKING;
            update emptyReq;
        test.stopTest();

        List<Case> allReq = [SELECT Id FROM Case];

        Equipment_Maintenance_Item__c workPart = [SELECT Id FROM Equipment_Maintenance_Item__c 
                                                    WHERE Maintenance_Request__c = :emptyReq.Id];

        System.assert(workPart != null);
        System.assert(allReq.size() == 1);

    }

    @isTest
    private static void testMaintenanceRequestBulk(){
        List<Vehicle__c> vehicleList = new List<Vehicle__c>();
        List<Product2> equipmentList = new List<Product2>();
        List<Equipment_Maintenance_Item__c> workPartList = new List<Equipment_Maintenance_Item__c>();
        List<Case> requestList = new List<Case>();
        List<Id> oldRequestIds = new List<Id>();

        for (Integer i=0; i<300; i++){
            vehicleList.add(createVehicle());
            equipmentList.add(createEq());            
        }
        insert vehicleList;
        insert equipmentList;

        for (Integer i=0; i<300; i++){
            requestList.add(createMaintenanceRequest(vehicleList[i].Id,equipmentList[i].Id));
        }
        insert requestList;

        for (Integer i=0; i<300; i++){
            workPartList.add(createWorkPart(equipmentList[i].Id,requestList[i].Id));
        }
        insert workPartList;

        test.startTest();
            for (Case req : requestList){
                req.Status = CLOSED;
                oldRequestIds.add(req.Id);
            }
            update requestList;
        test.stopTest();

        List<Case> allrequestList = [SELECT Id FROM Case WHERE Status = :STATUS_NEW];

        List<Equipment_Maintenance_Item__c> workParts = [SELECT Id FROM Equipment_Maintenance_Item__c 
                                                            WHERE Maintenance_Request__c IN :oldRequestIds];

        System.assert(allrequestList.size() == 300);
    }
}