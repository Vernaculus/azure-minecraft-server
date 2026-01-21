## Lessons Learned: SKU Selection in Production

### Challenge: Azure Capacity Constraints
During deployment, encountered real-world Azure capacity limitations that required systematic troubleshooting.

#### Initial Plan vs Reality
- **Target SKU**: Standard_B1ms (1 vCPU, 2 GB RAM) - Not available in East US
- **Root Cause**: Legacy B-series deprecated/unavailable in modern subscriptions
- **Attempted Alternatives**: B2s_v2 (ARM-based, incompatible), A2_v2 (no capacity), D2s_v3 (no capacity), DS1_v2 (no capacity)

#### Discovery Process
1. **Quota vs Capacity**: Quota available (10 vCPUs) but no physical datacenter capacity
2. **Region Issues**: East US and South Central US had severe capacity saturation
3. **Systematic Testing**: Used `az vm list-skus` to find SKUs with "None" restrictions
4. **Final Solution**: Standard_D2as_v6 - latest AMD generation, actually available

#### Final Selection: Standard_D2as_v6
- **Specs**: 2 vCPU (AMD EPYC Genoa), 8 GB RAM
- **Architecture**: x86-64 (Minecraft-compatible)
- **Cost**: ~$73/month (24/7), ~$24/month with 6hr/day auto-shutdown
- **Availability**: No capacity restrictions in South Central US
- **Performance**: Latest v6 generation, excellent for 10+ players

### Real-World Skills Demonstrated
- Quota vs capacity troubleshooting
- Azure region capacity analysis
- SKU compatibility verification (x86 vs ARM, Gen1 vs Gen2)
- Cost optimization under constraints
- Systematic problem-solving with Azure CLI

### Production Recommendation
Always check `az vm list-skus --location <region> --all` for "None" restrictions before committing to infrastructure design. Treat capacity as dynamic, not guaranteed.

