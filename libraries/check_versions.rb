class Chef
    class Recipe
        # version check functions. Convert version string to numeric string
        def version_split(in_string)
            out_version=[]
            in_string.split(/[^0-9]/).each do  |ver_part| out_version.push(ver_part.to_i) end
            return out_version
        end

        # version check functions. Compare string versions major-to-minor
        def v1_older_v2(v1="0.0.0_0", v2="0.0.0_0")
            v1_n = version_split(v1)
            v2_n = version_split(v2)
            i = 0
            while ( v1_n[i] && v2_n[i] ) do
                if v1_n[i] < v2_n[i]
                    return true
                elsif v1_n[i] > v2_n[i]
                    return false
                end
                i+=1
            end
            # versions equal case
            return false
        end
    end
end
