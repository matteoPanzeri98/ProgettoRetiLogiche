----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.02.2020 10:56:23
-- Design Name: 
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    Port (
           i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR(7 downto 0);
           o_address : out STD_LOGIC_VECTOR(15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR(7 downto 0)
           );
end project_reti_logiche;

architecture behavioral of project_reti_logiche is 
  --definizione del tipo stato e degli stati
  --start:stato iniziale della FSM imposto il segnale read enable 1 e mi preparo a leggere il segnale da valutare
  --statoCaricamento:stato che fa da passaggio tra uno stato e l'altro da tempo ai segnali di essere caricati dalla memoria 
  --leggiDaValutare:stato in cui si legge il contenuto di RAM(8)
   --caricaWz:stato in cui si legge il contenuto della memoria
  --esaminaWz:stato in cui se il valore da esaminare (estratto in leggiDaValutare) appartiene alla Wz letta in (caricaWz) passa in elaboraDati 
  --se non appartiene alla Wz corrente passa alla lettura della successiva e se ha raggiunto RAM(7) aggiunge il bit 0 davanti all'indirizzo e passa
  --allo stato done  
  --done:stato in cui si notifica con o_done=1 l'avvenuta elaborazione dei dati 
  --elaboraDati:stato in cui appurato che l'indirizzo da valutare appartiene alla data Wz si elabora e si scrive in memoria RAM(9) il valore elaborato 
  --waitStartZero:stato finale che attende che venga messo start=0 per abbassare anche done 
  type state_type is(start,statoCaricamento,leggiDaValutare,esaminaWz,caricaWz,done,elaboraDati,waitStartZero);
  signal statoCorrente,statoProssimo:state_type;
  begin     
    process(i_rst,i_clk)
    
    --dichiarazione variabili 
    variable indirizzoDaValutare:std_logic_vector(15 downto 0):=std_logic_vector(to_unsigned(8,16));--indirizzo di RAM(8)
    variable indirizzoScrittura:std_logic_vector(15 downto 0):=std_logic_vector(to_unsigned(9,16));--indirizzo di RAM(9)
    variable indirizzoWZLetta:std_logic_vector(15 downto 0);--contiene l'indirizzo della cella di memoria appena letta
    variable valoreDaValutare:integer range 0 to 127;--conterrà il valore di RAM(8)
    variable valoreLetto:integer range 0 to 127;--conterrà il valore estratto dalla memoria
    variable valoreDaScrivere:integer range 0 to 127; --conterrà il valore da scrivere in RAM(9)
    variable wzDaEsaminare:integer; --è "l'indice" della WZ da esaminare 
    variable wzOffset:std_logic_vector(3 downto 0):="0000";--conterrà WZ_OFFSET 
    
    begin
    
        if i_rst='1' then
            o_done<='0';
            o_en<='0';
            o_we<='0';
            statoCorrente<=start;
        elsif(i_clk' event and i_clk='1') then 
                
                case statoCorrente is                
                    when statoCaricamento=>
                        if(statoProssimo=leggiDaValutare) then
                            statoCorrente<=leggiDaValutare;
                        end if;
                        if(statoProssimo=esaminaWz)then 
                            statoCorrente<=esaminaWz;
                        end if;
                              
                    when start=> 
                        if(i_rst='0' and i_start='1') then                        
                            o_en<='1';
                            indirizzoWZLetta:=std_logic_vector(to_unsigned(0,16));
                            o_address<=indirizzoDaValutare;--ha valore fisso
                            wzDaEsaminare:=1;                        
                            statoCorrente<=statoCaricamento;
                            statoProssimo<=leggiDaValutare;                        
                        end if;
                        
                    when leggiDaValutare=>
                        valoreDaValutare:=to_integer(unsigned(i_data));
                        statoCorrente<=caricaWZ;
                    when caricaWz=>                         
                         o_address<=indirizzoWZLetta;
                         statoCorrente<=statoCaricamento;
                         statoProssimo<=esaminaWz;
                         
                    when esaminaWz=>
                         valoreLetto:=to_integer(unsigned(i_data));
                         if( wzDaEsaminare<=8 and (valoreDaValutare<valoreLetto or valoreDaValutare>=valoreLetto+4)) then 
                            indirizzoWZLetta:=std_logic_vector(to_unsigned(wzDaEsaminare,16));
                            wzDaEsaminare:=wzDaEsaminare+1;
                            statoCorrente<=caricaWZ;
                         elsif(wzDaEsaminare>8) then 
                            o_address<=indirizzoScrittura;
                            o_we<='1';
                            o_data<='0' & std_logic_vector(to_unsigned(valoreDaValutare,7));
                            statoCorrente<=done;
                        else                           
                           statoCorrente<=elaboraDati;                           
                        end if;
                        
                   when elaboraDati=>
                       o_address<=indirizzoScrittura;
                       o_we<='1';                      
                       case (valoreDaValutare- valoreLetto) is
                           when 0=>
                               wzOffset:="0001";
                           when 1=>
                               wzOffset:="0010"; 
                           when 2=>
                               wzOffset:="0100"; 
                           when 3=>
                               wzOffset:="1000"; 
                           when others=>
                               wzOffset:="0000"; 
                           end case;
                       o_data<='1'& std_logic_vector(to_unsigned(wzDaEsaminare-1,3))&wzOffset ;                       
                       statoCorrente<=done;     
                    when done=>
                        o_en<='0';
                        o_we<='0';
                        o_done<='1';    
                        
                        statoCorrente<=waitStartZero;
                        
                    when waitStartZero=>
                        if(i_start='0') then 
                            o_done<='0';
                            statoCorrente<=start;
                        else 
                            statoCorrente<=waitStartZero;
                           
                        end if;              
                 end case;
            end if;      
    end process;
end behavioral;
