library(dagitty)
library(ggdag)
library(ggplot2)

# Visualize the causal model for this research study

G <- dag("{Age -> Law; Crime_Severity -> Law -> Judge -> Set_Bail -> Bail_Amount;
         Race -> Bias; Ethnicity -> Bias;
         Age -> Bias; Representation -> Judge; Judge -> Set_Bail;
         Bias -> Judge; Crime_Severity -> Judge;
         Gender -> Bias; Affordability -> Judge;
         Age -> Affordability; Race -> Affordability; Ethnicity -> Affordability; Gender -> Affordability;
         Convictions -> Judge; Set_Bail -> Null_Bail_Amt}")

ggdag(G, text_size = 2.2, node_size = 22) + theme_void()                          

