public with sharing class CaseNotificationRequestDto {
    
        public String caseId { get; set; }
        public String personCode { get; set; }
        public String origin { get; set; }
        public String event { get; set; }
        public String caseNumber { get; set; }
        public Typology typology { get; set; }
    
        public class Typology {
            public String type { get; set; }
            public String reason { get; set; }
        }
        
}