package Combinations is
   type Combination_Array is array (Positive range <>) of Natural; -- array of n + 1 element

   procedure Get_Next_Combination
     (C           : in out Combination_Array;
      K           : in out Positive;
      Is_Finished :    out Boolean);
end Combinations;