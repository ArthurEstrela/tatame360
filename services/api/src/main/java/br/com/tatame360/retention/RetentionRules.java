package br.com.tatame360.retention;

public final class RetentionRules {
    private RetentionRules(){}
    public record Factors(int baselineCount,int recentCount,int daysSinceAttendance,int inactiveWeeks){}
    public record Result(int score,String band,int recencyPenalty,int dropPenalty,int regularityPenalty){}
    public static Result calculate(Factors factors){
        if(factors.baselineCount<0||factors.recentCount<0||factors.daysSinceAttendance<0||factors.inactiveWeeks<0||factors.inactiveWeeks>2)throw new IllegalArgumentException("Invalid retention factors");
        int recency=factors.daysSinceAttendance<7?0:factors.daysSinceAttendance<14?15:factors.daysSinceAttendance<21?30:45;
        double baseline=factors.baselineCount/3.0;
        double ratio=baseline<1?0:Math.max(0,1-factors.recentCount/baseline);
        int drop=ratio<0.25?0:ratio<0.5?10:ratio<0.75?20:35;
        int regularity=10*factors.inactiveWeeks;
        int score=Math.clamp(100-recency-drop-regularity,0,100);
        return new Result(score,band(score),recency,drop,regularity);
    }
    public static String band(int score){return score>=80?"SAUDAVEL":score>=60?"OBSERVAR":score>=40?"ATENCAO":"PRIORITARIA";}
}
