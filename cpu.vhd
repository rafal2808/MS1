library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu is
    Port (
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        input_port : in  STD_LOGIC_VECTOR(7 downto 0);
        output_port : out STD_LOGIC_VECTOR(7 downto 0)
    );
end cpu;

architecture Behavioral of cpu is

    type state_type is (Fetch, Decode, Execute, WriteBack);
    signal state : state_type := Fetch;

    signal pc        : unsigned(3 downto 0) := (others => '0');
    signal instr     : STD_LOGIC_VECTOR(7 downto 0);
    signal opcode    : STD_LOGIC_VECTOR(3 downto 0);
    signal operand   : STD_LOGIC_VECTOR(3 downto 0);

    signal regA      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal regB      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal alu_result: STD_LOGIC_VECTOR(7 downto 0);

    type memory_type is array (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
    signal ROM : memory_type := (
        0 => "00010000", -- LD A, 0
        1 => "00100001", -- LD B, 1
        2 => "01000000", -- ADD
        3 => "00100010", -- LD B, 2
        4 => "01000000", -- ADD
        5 => "10000000", -- OUT
        6 => "11110000", -- HLT
        others => (others => '0')
    );
    signal RAM : memory_type := (
        0 => "00000010", -- 2
        1 => "00000001", -- 1
        2 => "00000001", -- 1
        others => (others => '0'));

begin

    process(clk, rst)
    begin
        if rst = '0' then
            pc <= (others => '0');
            instr <= (others => '0');
            opcode <= (others => '0');
            operand <= (others => '0');
            regA <= (others => '0');
            regB <= (others => '0');
            alu_result <= (others => '0');
            output_port <= (others => '0');
            state <= Fetch;
        elsif rising_edge(clk) then
            case state is
                when Fetch =>
                    instr <= ROM(to_integer(pc));
                    state <= Decode;
                when Decode =>
                    opcode <= instr(7 downto 4);
                    operand <= instr(3 downto 0);
                    state <= Execute;
                when Execute =>
                    case opcode is
                        when "0000" => -- NOP
                            null;
                        when "0001" => -- LOAD A
                            regA <= RAM(to_integer(unsigned(operand)));
                        when "0010" => -- LOAD B
                            regB <= RAM(to_integer(unsigned(operand)));
                        when "0011" => -- STORE A
                            RAM(to_integer(unsigned(operand))) <= regA;
                        when "0100" => -- ADD
                            alu_result <= std_logic_vector(unsigned(regA) + unsigned(regB));
                            --instr_reg <= instr;
                        when "0101" => -- SUB
                            alu_result <= std_logic_vector(unsigned(regA) - unsigned(regB));
                            --instr_reg <= instr;
                        when "1000" => -- OUT
                            output_port <= regA;
                        when "1001" => -- IN
                            regA <= input_port;
                        when "1111" => -- HLT
                            state <= Execute;
                        when others =>
                            null;
                    end case;
                    pc <= pc + 1;
                    if opcode /= "1111" then
                        state <= WriteBack;
                    end if;
                when WriteBack =>
                    if opcode = "0100" or opcode = "0101" then
                        regA <= alu_result;
                    end if;
                    state <= Fetch;
            end case;
        end if;
    end process;

end Behavioral;
