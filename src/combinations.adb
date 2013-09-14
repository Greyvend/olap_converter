package body Combinations is

procedure Get_Next_Combination (C : in out Combination_Array;
                                K : in out Positive;
                                Is_Finished : out Boolean) is
   function Uninitialized return Boolean;
   function Finished return Boolean;
   procedure Init (K : in Positive);

   function Uninitialized return Boolean is
   begin
      for I in C'Range loop
         if C(I) /= 0 then
            return False;
         end if;
      end loop;
      return True;
   end Uninitialized;

   function Finished return Boolean is
   begin
      for I in 1..C'Length - 1 loop
         if C(I) /= I + 1 then
            return False;
         end if;
      end loop;
      return True;
   end Finished;

   procedure Init (K : in Positive) is
   begin
      for I in 1..K loop
         C(I) := I;
      end loop;
      C(K + 1) := C'Length; -- n + 1
   end Init;

   J : Natural := 0;
begin -- Get_Next_Combination
   Is_Finished := False;
   if Uninitialized then
      Init (K);
      return;
   elsif Finished then
      Is_Finished := True;
      return;
   end if;

   if C(1) + 1 < C(2) then
      C(1) := C(1) + 1;
      return;
   else
      J := 2;

      Climb_Loop:
      loop
         C(J - 1) := J - 1;
         if C(J) + 1 = C(J + 1) then
            J := J + 1;
         else
            -- if J > k then Inc K and go on again
            -- if K = N - 1 then return and do no more
            if J > K then
               if K + 1 < C'Length - 1 then
                  K := K + 1;
                  Init (K);
               end if;
               return;
            else
               C(J) := C(J) + 1;
               return;
            end if;
         end if;
      end loop Climb_Loop;

   end if;
end Get_Next_Combination;

end Combinations;