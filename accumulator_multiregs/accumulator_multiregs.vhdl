library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator_multiregs is
  port(
    i_val_acc   : std_logic; -- Signals whether accumulator is ready to receive new input data
    reset       : in std_logic; -- Reset signal
    clk         : in std_logic; -- Clock signal
    r_s         : in std_logic_vector(1 downto 0); -- Register selector
    i_data      : in std_logic_vector(8 downto 0); -- Input data
    o_data      : out std_logic_vector(31 downto 0); -- Output data
    o_val_acc   : out std_logic -- Signal for completion of computations
  );
end accumulator_multiregs;

architecture rtl of accumulator_multiregs is
  signal first_dff        : std_logic_vector(8 downto 0) := (others => '0'); -- Buffer for the input data
  signal delay_val        : std_logic_vector(1 downto 0) := (others => '0'); -- Singal for pipeline progress
  -- signal o_acc            : std_logic_vector(31 downto 0) := (others => '0'); -- Accumulation registers
  type registers_delta is array (3 downto 0) of std_logic_vector(31 downto 0); -- Delta accumulation registers of size 32 bits (TODO: nr of regs and bit width should be generic)
  signal registers_d : registers_delta := (others => (others => '0'));
  signal o_reg_acc        : std_logic_vector(31 downto 0) := (others => '0'); -- Buffer for the output data
  -- signal r_sel            : std_logic_vector(1 downto 0) := (others => '0');
begin

  -- Load input data into first_dff (input buffer)
  process(clk) begin
    if rising_edge(clk) then
      if reset = '1' then
        first_dff <= (others => '0');
      elsif i_val_acc = '1' then
        first_dff <= i_data;
        -- r_sel <= r_s;
      end if;
    end if;
  end process;

  -- Accumulate input value in o_acc (accumulation register)
  process(first_dff) begin
    if delay_val(0) = '1' then
      o_reg_acc <= std_logic_vector(unsigned(registers_d(to_integer(unsigned(r_s)))) + unsigned(first_dff));
    end if;
  end process;

  -- Copy current accumulation result to register
  process(clk) begin
    if rising_edge(clk) then
      if reset = '1' then
        o_reg_acc <= (others => '0');
      else
        if delay_val(1) = '1' then
          registers_d(to_integer(unsigned(r_s))) <= o_reg_acc;
        end if;
      end if;
    end if;
  end process;

  -- Determine delay through pipeline to set flag for finished computations
  process(clk) begin
    if rising_edge(clk) then
      delay_val <= delay_val(0) & i_val_acc;
      if delay_val(1) = '1' then
        o_val_acc <= '1';
      else
        o_val_acc <= '0';
      end if;
    end if;
  end process;

  -- Send result of accumulation to output pins
  process(clk) begin
    if rising_edge(clk) then
      if reset = '1' then
        o_data <= (others => '0');
      else
        o_data <= o_reg_acc;
      end if;
    end if;
  end process;

end rtl;
