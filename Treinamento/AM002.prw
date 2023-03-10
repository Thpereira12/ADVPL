
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//--------------------------------------------------
	/*/{Protheus.doc} Estudo de lógica, Fatorial e For

	@author Thierry Pereira
	@since 10/01/2023

	@return
	/*/
//--------------------------------------------------

User Function CalcFator()
Local nCnt
Local nResultado := 1  //Resultado Fatorial 
Local Nfator := 5      //Número para o cálculo 

// Cálculo do Fatorial 
For nCnt := Nfator to step -1
    nResultado *= nCnt
next nCnt

// Exibe o resultado na tela, através da função alert 
MsgAlert("O Fatorial de " +  cValToChar(nFator) + ; // Salto de linha usando o ; 
" é " +  CValToChar(nResultado))                       // Uso de Caractere concatenado com número convertido em caractere 


// Termina o programa
Return (NIL)
