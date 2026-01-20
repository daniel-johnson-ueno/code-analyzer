public class CompareConversationEntryBySeq implements Comparator<ConversationEntry>{
    public Integer compare(ConversationEntry ce1, ConversationEntry ce2){
        return ce1.Seq - ce2.Seq;
    }
}