package br.com.tatame360.retention;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class RetentionRulesTest {
    @Test void exampleWithGradualDropScoresSeventy() {
        var result=RetentionRules.calculate(new RetentionRules.Factors(9,1,3,1));
        assertThat(result.score()).isEqualTo(70);
        assertThat(result.band()).isEqualTo("OBSERVAR");
    }
    @Test void exampleWithNoRecentTrainingScoresForty() {
        var result=RetentionRules.calculate(new RetentionRules.Factors(9,0,10,1));
        assertThat(result.score()).isEqualTo(40);
        assertThat(result.band()).isEqualTo("ATENCAO");
    }
    @Test void boundariesMatchTheProductDefinition() {
        assertThat(RetentionRules.band(39)).isEqualTo("PRIORITARIA");
        assertThat(RetentionRules.band(40)).isEqualTo("ATENCAO");
        assertThat(RetentionRules.band(59)).isEqualTo("ATENCAO");
        assertThat(RetentionRules.band(60)).isEqualTo("OBSERVAR");
        assertThat(RetentionRules.band(79)).isEqualTo("OBSERVAR");
        assertThat(RetentionRules.band(80)).isEqualTo("SAUDAVEL");
    }
    @Test void rejectsImpossibleFactors() {
        assertThatThrownBy(() -> RetentionRules.calculate(new RetentionRules.Factors(-1,0,0,0)))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
