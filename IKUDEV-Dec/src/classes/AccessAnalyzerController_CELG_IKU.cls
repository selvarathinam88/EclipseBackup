/************************************************************************************************
* Class Name   : AccessAnalyzerController_CELG_IKU 
* Description  : Controller for the visual force page 'AccessAnalyzer_CELG_IKU'
                 Provides ability to create access request for Analyzer Tools and Applications
* Created By   : Deloitte
* Created On   : 15th Dec,2016
*************************************************************************************************/
public class AccessAnalyzerController_CELG_IKU extends PageControllerBase_CELG_IKU {
    public SelectUsersCompController_CELG_IKU mySelectUsersComponentController   {get;set;}
    public DataAssetApproval_CELG_IKU__c obj {get; set;}
    public List<AnalyzerToolsandApplications_CELG_IKU__c> lstAnalyzerRec {get;set;}
    public String selectedEnterpriseApplications{get;set;}
    public String selectedAnalyzerTools{get;set;}
    public List<String> warningMessages{get;set;}
    public String[] existingEntities = New String[]{};
    public Map<Id, List<DataAsset_CELG_IKU__c>> analyzerToolsDataSetsMap{get;set;}
    public string Id{get;set;}
    public Boolean isDataSteward {get;set;}
    public DataAssetApproval_CELG_IKU__c reqRecord{get;set;}
    
    /**************************************************************************
    * Description  : Constructor of the controller to initialize variables
    * Return Type  : void
    * Parameter    : void
    ***************************************************************************/  
    public AccessAnalyzerController_CELG_IKU()
    {
        mySelectUsersComponentController = new SelectUsersCompController_CELG_IKU();
        obj = new DataAssetApproval_CELG_IKU__c();
        warningMessages = new  List<String>();
        isDataSteward = false;
        isDataSteward = CommonUtilities_CELG_IKU.isDataSteward(UserInfo.getUserId());        
    }    
    
    /**********************************************************************************
    * Description  : Method to fetch the Analyzer Tools
    * Return Type  : List<AnalyzerToolsandApplications_CELG_IKU__c> 
    * Parameter    : void
    ***********************************************************************************/ 
    public List<AnalyzerToolsandApplications_CELG_IKU__c> AnalyzerToolRec
    {
        get { 
            List<AnalyzerToolsandApplications_CELG_IKU__c> AnalyzerToolRec = new List<AnalyzerToolsandApplications_CELG_IKU__c>();
            for (AnalyzerToolsandApplications_CELG_IKU__c n : [SELECT id, Name,Status_CELG_IKU__c,Description_CELG_IKU__c FROM AnalyzerToolsandApplications_CELG_IKU__c 
                                                               WHERE IsAccessibleTool__c =: true AND recordTypeId = :Label.AnalyzerToolsRecordTypeId_CELG_IKU ORDER By Name ASC]) 
            {
                AnalyzerToolRec.add(n);
            }
            return AnalyzerToolRec;
        }
        set;
    }
    
    /**********************************************************************************
    * Description  : Method to fetch the Analyzer Applications
    * Return Type  : List<AnalyzerToolsandApplications_CELG_IKU__c> 
    * Parameter    : void
    ***********************************************************************************/ 
    public List<AnalyzerToolsandApplications_CELG_IKU__c> AnalyzerApplicationRec
    {
        get { 
            List<AnalyzerToolsandApplications_CELG_IKU__c> AnalyzerApplicationRec = new List<AnalyzerToolsandApplications_CELG_IKU__c>();
            for (AnalyzerToolsandApplications_CELG_IKU__c n : [SELECT id, Name,Status_CELG_IKU__c,Description_CELG_IKU__c FROM AnalyzerToolsandApplications_CELG_IKU__c 
                                                               WHERE IsAccessibleTool__c =: true AND recordTypeId = :Label.AnalyzerApplicationsRecordTypeId_CELG_IKU ORDER By Name ASC]) 
            {
                AnalyzerApplicationRec.add(n);
            }
            return AnalyzerApplicationRec;
        }
        set;
    }
    
    /***********************************************************************************************************
    * Description  : Method to create Access request for Analyzer Tools, Applications & Enterprise Data Sets
    * Return Type  : pageReference 
    * Parameter    : void
    ***********************************************************************************************************/ 
    public pageReference createRequest()
    {
        List<String> lstAnalyzerApps = new List<String>();
        List<String> lstAnalyzerTool = new List<String>();
        List<DataAssetApproval_CELG_IKU__c>  analyzerToolsForApproval = new List<DataAssetApproval_CELG_IKU__c>();
        List<DataAssetApproval_CELG_IKU__c>  analyzerToolsForApprovalQueue = new List<DataAssetApproval_CELG_IKU__c>();
        List<DataAssetApproval_CELG_IKU__c>  analyzerAppsForApproval = new List<DataAssetApproval_CELG_IKU__c>();
        List<AnalyzerToolsAndApplications_CELG_IKU__c> lstAnalyzerToolsToApprove  = new list<AnalyzerToolsAndApplications_CELG_IKU__c>();
        List<AnalyzerToolsAndApplications_CELG_IKU__c> lstAnalyzerApplicationsToApprove  = new list<AnalyzerToolsAndApplications_CELG_IKU__c>();
        Set<String> noTrainingReqAppSet = new Set<String>();        
        List<Id> selectedUserIds =  new List<Id>();
        List<DataAssetApproval_CELG_IKU__c> requestRecList;
        List<Id> allReqIds = new List<Id>();
        List<User> lstUser = new List<User>();
        List<User> seletedUserList = new List<User>();
        List<Approval.ProcessSubmitRequest> lstDataSetApprovalProcess = new List<Approval.ProcessSubmitRequest>();
        String domain = System.URL.getSalesforceBaseURL().toExternalForm();
        boolean isApprovalProcessInvokedTools = false;
        PageReference pageRef;        
        
        //Check for Mandatory fields
        if(obj.WhatIsTheBusinessRationale_CELG_IKU__c == null || obj.WhatIsTheBusinessRationale_CELG_IKU__c == ''||mySelectUsersComponentController.selectedUsers == NULL 
           || mySelectUsersComponentController.selectedUsers.isEmpty()){
            warningMessages.clear();
            warningMessages.add(Label.RequiredFieldsErrorMessage_CELG_IKU);
            return pageRef;
        }else if((selectedEnterpriseApplications == null || selectedEnterpriseApplications == '') && 
                 (selectedAnalyzerTools == null || selectedAnalyzerTools == '')){
            warningMessages.clear();
            warningMessages.add(Label.ErrorMessageOnNullSelection_CELG_IKU);
            return pageRef;
        }
        else{
            if(selectedEnterpriseApplications != NULL && selectedEnterpriseApplications != ''){
                lstAnalyzerApps = selectedEnterpriseApplications.split('-');
            }
            if(selectedAnalyzerTools != NULL && selectedAnalyzerTools != ''){
                lstAnalyzerTool = selectedAnalyzerTools.split('-');
            }
            
            //getAll the Ids from te selected User
            if(mySelectUsersComponentController.selectedUsers != NULL && !mySelectUsersComponentController.selectedUsers.isEmpty()){
                for(SelectOption userRecOption : mySelectUsersComponentController.selectedUsers){
                    selectedUserIds.add(userRecOption.getValue());
                }
            }
        }

        lstUser = [Select id,name,email from User where Id=:Label.HardCodedApproverforAnalyzerTools_CELG_IKU];
        seletedUserList = [Select id,Name,email from User where Id In :selectedUserIds];
            lstAnalyzerToolsToApprove = [Select Id, Name from AnalyzerToolsAndApplications_CELG_IKU__c where Name in: lstAnalyzerTool];
            lstAnalyzerApplicationsToApprove = [Select Id, Name from AnalyzerToolsAndApplications_CELG_IKU__c where Name in: lstAnalyzerApps];
            DataAssetApproval_CELG_IKU__c reqObject ;
        Set<Id> toolsAndAppsIdSet = new Set<Id>();
        Map<Id,Set<Id>> toolsNAppssUserMap = new Map<Id,Set<Id>>();
        Map<String,Set<Id>> toolsNAppssUserMapForEmailBody = new Map<String,Set<Id>>();
        Map<Id,String> userIdNameMap = new Map<Id,String>();
        Map<Id,String> userIdEmailMap = new Map<Id,String>();
        if(seletedUserList != NULL && !seletedUserList.isEmpty()){
            for(User rec : seletedUserList){
                userIdNameMap.put(rec.Id, rec.Name);
                userIdEmailMap.put(rec.Id, rec.Email);
            }
        }
        if(lstAnalyzerToolsToApprove != NULL && !lstAnalyzerToolsToApprove.isEmpty()){
            for(AnalyzerToolsAndApplications_CELG_IKU__c rec : lstAnalyzerToolsToApprove){
                toolsAndAppsIdSet.add(rec.Id);
            }
        }
        if(lstAnalyzerApplicationsToApprove != NULL && !lstAnalyzerApplicationsToApprove.isEmpty()){
            for(AnalyzerToolsAndApplications_CELG_IKU__c rec : lstAnalyzerApplicationsToApprove){
                toolsAndAppsIdSet.add(rec.Id);  
            }
        }
        List<DataAssetApproval_CELG_IKU__c> requestRelToAnalyzerToolNAppList = [SELECT Id,Name,Requestor_CELG_IKU__c,AnalyzerToolsAndApplications_CELG_IKU__c FROM DataAssetApproval_CELG_IKU__c 
                                                                                    WHERE AnalyzerToolsAndApplications_CELG_IKU__c in: toolsAndAppsIdSet AND ApprovalStatus_CELG_IKU__c != : Label.RejectedStatus_CELG_IKU];
        //create the Map for Tools and Apps and Users
        if(requestRelToAnalyzerToolNAppList != NULL && !requestRelToAnalyzerToolNAppList.isEmpty()){
            for(DataAssetApproval_CELG_IKU__c  rec : requestRelToAnalyzerToolNAppList){
                if(toolsNAppssUserMap.get(rec.AnalyzerToolsAndApplications_CELG_IKU__c ) != NULL){
                    Set<Id> tempSet = toolsNAppssUserMap.get(rec.AnalyzerToolsAndApplications_CELG_IKU__c);
                    tempSet.add(rec.Requestor_CELG_IKU__c);
                    toolsNAppssUserMap.put(rec.AnalyzerToolsAndApplications_CELG_IKU__c, tempSet);
                }else{
                    Set<Id> tempSet = new Set<Id>();
                    tempSet.add(rec.Requestor_CELG_IKU__c);
                    toolsNAppssUserMap.put(rec.AnalyzerToolsAndApplications_CELG_IKU__c, tempSet);
                }
            }
        }
        if(!String.isEmpty(Label.ApplicationNoTrainingReq_CELG_IKU)){
            for(String appName : Label.ApplicationNoTrainingReq_CELG_IKU.split(';')){
                noTrainingReqAppSet.add(appName);
            }
        }
        if(!lstAnalyzerToolsToApprove.isEmpty()){
            for(AnalyzerToolsAndApplications_CELG_IKU__c rec : lstAnalyzerToolsToApprove){
                for(Id userId : selectedUserIds){
                    if(toolsNAppssUserMap.get(rec.Id) == NULL || !toolsNAppssUserMap.get(rec.Id).contains(userId)){
                        if(returnAnalyzerToolsForApproval().contains(rec.Name)){
                            reqObject = new DataAssetApproval_CELG_IKU__c();
                            reqObject.ApprovalStatus_CELG_IKU__c = Label.PendingStatus_CELG_IKU ;
                            reqObject.Name = rec.Name;
                            reqObject.Requestor_CELG_IKU__c = userId;
                            reqObject.AnalyzerToolsAndApplications_CELG_IKU__c = rec.Id;                
                            reqObject.WhatIsTheBusinessRationale_CELG_IKU__c = obj.WhatIsTheBusinessRationale_CELG_IKU__c;                
                            reqObject.RecordTypeId = Label.AnalyzerToolRequestRecordTypeId_CELG_IKU;
                            reqObject.RequestType_CELG_IKU__c =  Label.Access;
                            analyzerToolsForApprovalQueue.add(reqObject);
                        }else{
                            reqObject = new DataAssetApproval_CELG_IKU__c();
                            reqObject.ApprovalStatus_CELG_IKU__c = Label.TechnicalProvisioningInProgress_CELG_IKU ;
                            reqObject.Name = rec.Name;
                            reqObject.Requestor_CELG_IKU__c = userId;
                            reqObject.AnalyzerToolsAndApplications_CELG_IKU__c = rec.Id;                
                            reqObject.WhatIsTheBusinessRationale_CELG_IKU__c = obj.WhatIsTheBusinessRationale_CELG_IKU__c;                
                            reqObject.RecordTypeId = Label.AnalyzerToolRequestRecordTypeId_CELG_IKU;
                            reqObject.RequestType_CELG_IKU__c =  Label.Access;
                            if(!lstUser.isEmpty())
                            {
                                reqObject.RequestOwner_CELG_IKU__c = lstUser[0].id;
                            }
                            analyzerToolsForApproval.add(reqObject);  
                        }    
                    }else{
                        if(toolsNAppssUserMapForEmailBody.get(rec.Name) != NULL){
                            Set<Id> tempSet = toolsNAppssUserMapForEmailBody.get(rec.Name);
                            tempSet.add(userId);
                            toolsNAppssUserMapForEmailBody.put(rec.Name, tempSet);
                        }else{
                            Set<Id> tempSet = new Set<Id>();
                            tempSet.add(userId);
                            toolsNAppssUserMapForEmailBody.put(rec.Name, tempSet);
                        }
                    }
                }        
            }
        }           
        if(!lstAnalyzerApplicationsToApprove.isEmpty()){
            for(AnalyzerToolsAndApplications_CELG_IKU__c rec : lstAnalyzerApplicationsToApprove ){
                for(Id userId : selectedUserIds){
                    if(toolsNAppssUserMap.get(rec.Id) == NULL || !toolsNAppssUserMap.get(rec.Id).contains(userId)){
                        reqObject = new DataAssetApproval_CELG_IKU__c();
                        if(noTrainingReqAppSet.contains(rec.Name)){
                            reqObject.ApprovalStatus_CELG_IKU__c = Label.TechnicalProvisioningInProgress_CELG_IKU;
                            if(!lstUser.isEmpty())
                            {
                                reqObject.RequestOwner_CELG_IKU__c = lstUser[0].id;
                            }
                        }else{
                            reqObject.ApprovalStatus_CELG_IKU__c = Label.AwaitingTrainingCompletion_CELG_IKU;
                        }
                        reqObject.Name = rec.Name;
                        reqObject.Requestor_CELG_IKU__c = userId;
                        reqObject.AnalyzerToolsAndApplications_CELG_IKU__c = rec.Id;                
                        reqObject.WhatIsTheBusinessRationale_CELG_IKU__c = obj.WhatIsTheBusinessRationale_CELG_IKU__c;                
                        reqObject.RecordTypeId = Label.AnalyzerApplicationRequestRecordTypeId_CELG_IKU;
                        reqObject.RequestType_CELG_IKU__c =  Label.Access;
                        analyzerAppsForApproval.add(reqObject);
                    }else{
                        if(toolsNAppssUserMapForEmailBody.get(rec.Name) != NULL){
                            Set<Id> tempSet = toolsNAppssUserMapForEmailBody.get(rec.Name);
                            tempSet.add(userId);
                            toolsNAppssUserMapForEmailBody.put(rec.Name, tempSet);
                        }else{
                            Set<Id> tempSet = new Set<Id>();
                            tempSet.add(userId);
                            toolsNAppssUserMapForEmailBody.put(rec.Name, tempSet);
                        }
                    }
                }
            }                
        }
        try{
            Database.UpsertResult[] sResult1;
            Database.UpsertResult[] sResult2;
            Database.UpsertResult[] sResult3;
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            List<Messaging.SingleEmailMessage> mails1 = new List<Messaging.SingleEmailMessage>();
            //Save the list
            if(!analyzerToolsForApproval.isEmpty()){
                sResult1 = Database.Upsert(analyzerToolsForApproval);                    
            }
            if(!analyzerAppsForApproval.isEmpty()){
                sResult2 = Database.Upsert(analyzerAppsForApproval);                    
            }
            if(!analyzerToolsForApprovalQueue.isEmpty()){
                sResult3 = Database.Upsert(analyzerToolsForApprovalQueue);                    
            }
            List<String> userEmailIds = CommonUtilities_CELG_IKU.getListOfUserEmailIdFromQueue(new List<String>{Label.DataSteward_CELG_IKU});
            Messaging.SingleEmailMessage mail;
            
            if(!analyzerToolsForApproval.isEmpty()){
                for(DataAssetApproval_CELG_IKU__c tempReq : analyzerToolsForApproval){
                    allReqIds.add(tempReq.Id);
                }
            }
            if(!analyzerAppsForApproval.isEmpty()){
                for(DataAssetApproval_CELG_IKU__c tempReq : analyzerAppsForApproval){
                    allReqIds.add(tempReq.Id);
                }
            }
            if(sResult3 != NULL){
                Approval.ProcessSubmitRequest sApprovalProcess;
                for(Database.UpsertResult rec : sResult3){
                    if(rec.isSuccess()){
                        sApprovalProcess = new Approval.ProcessSubmitRequest();
                        sApprovalProcess.setComments(Label.SubmittedforApproval_CELG_IKU);
                        sApprovalProcess.setObjectId(rec.getId());
                        Approval.ProcessResult result = Approval.process(sApprovalProcess);
                    } 
                }
            }
            if(toolsNAppssUserMapForEmailBody != NULL && toolsNAppssUserMapForEmailBody.keySet() != NULL 
               && !toolsNAppssUserMapForEmailBody.keySet().isEmpty()){
                   //Fetch loggedin user email/ submitter
                   List<String> userEmailIds1 = new List<String>{UserInfo.getUserEmail()};
                       Messaging.SingleEmailMessage mail1 = new Messaging.SingleEmailMessage();
                   String subjectText = Label.AnalyzerMailSubject_CELG_IKU;
                   String emailBody1 = '';
                   String emailBody2 = '';
                   String body = '';
                   emailBody1 = Label.AnalyzerDuplicateEmailBody_CELG_IKU+'&nbsp;'+UserInfo.getName()+'</br><br/>'+Label.AnalyzerDuplicateEmailBody1_CELG_IKU+'</br></br>';
                   for(String recName : toolsNAppssUserMapForEmailBody.keySet()){                          
                       for(Id requesterId : toolsNAppssUserMapForEmailBody.get(recName)){
                           emailBody2 = emailBody2 +'<b>'+ recName +'</b>&nbsp;:&nbsp;<b>'+userIdNameMap.get(requesterId)+'</b></br>';
                       }
                   }
                   body = emailBody1+emailBody2+'<br/>'+Label.RetireEmailBodyAnalyzerDS7_CELG_IKU+'<br/>'+Label.RetireEmailBodyAnalyzerDS8_CELG_IKU;
                   mail1.setToAddresses(userEmailIds1);
                   mail1.setSubject(subjectText);
                   mail1.setHtmlBody(body);
                   mails1.add(mail1);
                   try{
                       Messaging.sendEmail(mails1);
                   }catch(System.EmailException ex){
                       CommonUtilities_CELG_IKU.createExceptionLog(ex);
                   }
               }
            if(!allReqIds.isEmpty()){
                requestRecList = [SELECT Id,Name,Requestor_CELG_IKU__r.Name,Requestor_CELG_IKU__r.Email_Id__c FROM DataAssetApproval_CELG_IKU__c WHERE Id In : allReqIds];
                if(requestRecList != NULL && !requestRecList.isEmpty()){
                    for(DataAssetApproval_CELG_IKU__c objRec : requestRecList){
                            mail = new Messaging.SingleEmailMessage();
                            String subjectText = Label.AnalyzerMailSubject_CELG_IKU;
                            String body = Label.AnalyzerEmailBody2_CELG_IKU+'&nbsp;'+'<b>'+objRec.Name+'</b>'+'&nbsp;'+Label.AnalyzerEmailBody3_CELG_IKU+'&nbsp;'+'<b>'+objRec.Requestor_CELG_IKU__r.Name+'</b>.'+
                                '<br/>'+Label.AnalyzerEmailBody4_CELG_IKU+'<br/><br/>'+Label.AnalyzerEmailBody5_CELG_IKU+'&nbsp;<b>'+objRec.Id+'</b><br/>'
                                +Label.AnalyzerEmailBody6_CELG_IKU+'&nbsp;<b>'+objRec.Name+'</b><br/>'+Label.AnalyzerEmailBody10_CELG_IKU+'&nbsp;<b>'+objRec.Requestor_CELG_IKU__r.Name+'</b><br/>'
                                +Label.AnalyzerEmailBody7_CELG_IKU+'&nbsp;<b>'+objRec.Requestor_CELG_IKU__r.Email_Id__c+'</b><br/><br/>'
                                +Label.AnalyzerEmailBody8_CELG_IKU+'&nbsp;'+'<a href="'+domain+'/' + objRec.Id +'">'+objRec.Name+'</a>.'
                                +Label.AnalyzerEmailBody9_CELG_IKU;
                            mail.setToAddresses(userEmailIds);
                            mail.setSubject(subjectText);
                            mail.setHtmlBody(body);
                            mails.add(mail);
                        }
                    }
                    try{
                        Messaging.sendEmail(mails);
                    }catch(System.EmailException ex){
                        CommonUtilities_CELG_IKU.createExceptionLog(ex);
                    } 
                }
                pageRef = new PageReference('/apex/ThankYou_Page_CELG_IKU?type=AccessAnalyzer');
                pageRef.setRedirect(true);                
            }
            catch(System.DMLException dmlExp){
                CommonUtilities_CELG_IKU.createExceptionLog(dmlExp);              
            } 
        
        
        return pageRef;
    }
    /***********************************************************************************************************
    * Description  : Method to edit the request in Initiated status
    * Return Type  : pageReference 
    * Parameter    : void
    ***********************************************************************************************************/ 
    public pageReference editRequest()
    {
        pageReference pg = null;
        pg = new pageReference('/apex/AccessToAnalyzer_CELG_IKU?Id='+reqRecord.Id+'&view=editMode');
        pg.setRedirect(true);
        return pg;
    }
    /***********************************************************************************************************
    * Description  : Method to save the request with Access Granted Status
    * Return Type  : pageReference 
    * Parameter    : void
    ***********************************************************************************************************/ 
    public PageReference saveRequest()
    {
        pageReference pg = null;
        if(reqRecord != null){
          reqRecord.ApprovalStatus_CELG_IKU__c = reqRecord.ApprovalStatus_CELG_IKU__c;
          reqRecord.AcknowledgmentComments_CELG_IKU__c = reqRecord.AcknowledgmentComments_CELG_IKU__c;
          upsert reqRecord;
          pg = new PageReference('/apex/AccessToAnalyzer_CELG_IKU?Id='+reqRecord.Id+'&view=finalMode');
          pg.setRedirect(true);
        }
        return pg;
    }
    /***********************************************************************************************************
    * Description  : Method to cancel Actions on Access to analyzer page
    * Return Type  : pageReference 
    * Parameter    : void
    ***********************************************************************************************************/ 
    public PageReference cancelRequest()
    {
        pageReference pg = null;
        pg = new PageReference('/apex/AccessToAnalyzer_CELG_IKU?Id='+reqRecord.Id+'&view=detail');
        pg.setRedirect(true);
        return pg;
    }
    
     /* 
    * @Method Name                    :  setComponentController
    * @Description                    :  set SelectUsersCompController_CELG_IKU object as compController.
    * @Return Type                    :  void
    * @Parameters                     :   
    */
    
    public override void setComponentController(ComponentControllerBase_CELG_IKU compController) {
         mySelectUsersComponentController  = (SelectUsersCompController_CELG_IKU)compController;
     }
    
    /* 
    * @Method Name                    :  returnAnalyzerToolsForApproval
    * @Description                    :  Returns set of Analyzer Tools Names which needs appoval.
    * @Return Type                    :  Set<String>
    * @Parameters                     :   
    */
    public Set<String> returnAnalyzerToolsForApproval(){
        Set<String> analyzerToolsForApprovalSet = new Set<String>();
        String analyzerToolsNames = Label.AnalyzerToolsForApproval_CELG_IKU;
        if(analyzerToolsNames.contains(';')){
            for(String rec : analyzerToolsNames.split(';')){
                analyzerToolsForApprovalSet.add(rec);
            }
        }else{
            analyzerToolsForApprovalSet.add(analyzerToolsNames);
        }
        return analyzerToolsForApprovalSet;
    }
    public void userActivityRecords() 
    {
        CommonUtilities_CELG_IKU.createUserActivityRecords('Request Access to Tools and Applications'); 
    }
}